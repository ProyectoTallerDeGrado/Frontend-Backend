"""Servicio de indicators: catalogo, valores por emprendimiento y resumen del panel."""

from __future__ import annotations

from datetime import UTC, date, datetime

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.csv_export import to_csv
from emprendeu.core.errors import Forbidden, NotFoundError
from emprendeu.core.periods import local_text, period_bounds
from emprendeu.modules.ai_assistant import AssistantService, LLMClient
from emprendeu.modules.alerts import AlertService
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.indicators import schemas as s
from emprendeu.modules.indicators.exceptions import IndicatorTypeNotFound, InvalidPeriod
from emprendeu.modules.indicators.models import TipoIndicador, ValorIndicador
from emprendeu.modules.indicators.repository import IndicatorRepository
from emprendeu.modules.mentoring import MentoringService
from emprendeu.modules.users import CurrentUser, build_user_service
from emprendeu.modules.ventures import VentureService


def _type_out(t: TipoIndicador) -> s.IndicatorTypeOut:
    return s.IndicatorTypeOut(
        tipo_indicador_id=t.tipo_indicador_id,
        nombre=t.nombre,
        descripcion=t.descripcion,
        tipo=t.tipo,
        unidad=t.unidad,
    )


# Reportes (CU21): titulo y columnas (clave, etiqueta). Las filas son diccionarios por clave.
REPORTS: dict[str, tuple[str, list[tuple[str, str]]]] = {
    "resumen": (
        "Resumen por emprendimiento",
        [
            ("emprendimiento", "Emprendimiento"),
            ("sector", "Sector"),
            ("etapa", "Etapa"),
            ("sesiones_realizadas", "Sesiones realizadas"),
            ("compromisos_pendientes", "Compromisos pendientes"),
            ("compromisos_vencidos", "Compromisos vencidos"),
            ("alertas_sin_resolver", "Alertas sin resolver"),
            ("ultimo_avance", "Último avance"),
        ],
    ),
    "sesiones": (
        "Sesiones de mentoría",
        [
            ("fecha", "Fecha"),
            ("emprendimiento", "Emprendimiento"),
            ("asesor", "Asesor"),
            ("tema", "Tema"),
            ("modalidad", "Modalidad"),
            ("estado", "Estado"),
        ],
    ),
    "alertas": (
        "Alertas de seguimiento",
        [
            ("fecha", "Detectada"),
            ("emprendimiento", "Emprendimiento"),
            ("tipo", "Tipo"),
            ("prioridad", "Prioridad"),
            ("estado", "Estado"),
            ("atendida_por", "Atendida por"),
        ],
    ),
    "indicadores": (
        "Indicadores por emprendimiento",
        [
            ("fecha", "Registrado"),
            ("emprendimiento", "Emprendimiento"),
            ("indicador", "Indicador"),
            ("valor", "Valor"),
            ("unidad", "Unidad"),
            ("periodo", "Periodo"),
        ],
    ),
}
EXPORT_LIMIT = 10_000
PREVIEW_LIMIT = 50

Row = dict[str, str | int | float | None]


def _check_period(desde: date | None, hasta: date | None) -> None:
    if desde and hasta and hasta < desde:
        raise InvalidPeriod


class IndicatorService:
    def __init__(self, session: AsyncSession, llm: LLMClient) -> None:
        self._session = session
        self._llm = llm
        self._repo = IndicatorRepository(session)
        self._entrepreneurs = EntrepreneurService(session)
        self._ventures = VentureService(session)
        self._mentoring = MentoringService(session)
        self._alerts = AlertService(session)
        self._audit = AuditService(session)

    async def list_types(self) -> list[s.IndicatorTypeOut]:
        return [_type_out(t) for t in await self._repo.list_types()]

    async def create_type(self, body: s.IndicatorTypeCreate) -> s.IndicatorTypeOut:
        row = TipoIndicador(
            nombre=body.nombre,
            descripcion=body.descripcion,
            tipo=body.tipo,
            unidad=body.unidad,
        )
        await self._repo.add(row)
        await self._repo.commit()
        return _type_out(row)

    async def _access(
        self, user: CurrentUser, venture_id: int, permission: str
    ) -> None:
        if user.can_staff(permission):
            return
        if await self._entrepreneurs.is_member(user.usuario_id, venture_id):
            return
        raise Forbidden("No tienes acceso a este emprendimiento.")

    async def add_value(
        self, user: CurrentUser, venture_id: int, body: s.ValueCreate
    ) -> s.ValueOut:
        await self._access(user, venture_id, "reportes:registro")
        if not await self._ventures.exists(venture_id):
            raise NotFoundError("Emprendimiento no encontrado.")
        kind = await self._repo.get_type(body.tipo_indicador_id)
        if kind is None:
            raise IndicatorTypeNotFound
        row = ValorIndicador(
            emprendimiento_id=venture_id,
            tipo_indicador_id=kind.tipo_indicador_id,
            valor=body.valor,
            periodo=body.periodo,
            fecha_registro=datetime.now(UTC),
        )
        await self._repo.add(row)
        await self._repo.commit()
        return self._value_out(row, kind)

    @staticmethod
    def _value_out(v: ValorIndicador, t: TipoIndicador) -> s.ValueOut:
        return s.ValueOut(
            valor_indicador_id=v.valor_indicador_id,
            emprendimiento_id=v.emprendimiento_id,
            tipo_indicador_id=v.tipo_indicador_id,
            indicador=t.nombre,
            unidad=t.unidad,
            valor=v.valor,
            periodo=v.periodo,
            fecha_registro=v.fecha_registro,
        )

    async def list_values(self, user: CurrentUser, venture_id: int) -> list[s.ValueOut]:
        await self._access(user, venture_id, "reportes:consulta")
        return [self._value_out(v, t) for v, t in await self._repo.values(venture_id)]

    async def overview(self) -> s.Overview:
        users = await build_user_service(self._session).stats()
        by_role = {
            k.removeprefix("rol:"): v for k, v in users.items() if k.startswith("rol:")
        }
        audit_total = await AuditService(self._session).total()
        ai = await AssistantService(self._session, self._llm).status()
        await self._session.execute(text("SELECT 1"))
        return s.Overview(
            usuarios=s.UsersOverview(
                total=users["total"],
                habilitadas=users["habilitadas"],
                deshabilitadas=users["deshabilitadas"],
                por_rol=by_role,
            ),
            acciones_auditadas=audit_total,
            emprendimientos_activos=len(await self._ventures.active_venture_ids()),
            alertas_abiertas=await AlertService(self._session).open_count(),
            servicios=[
                s.ServiceStatus(
                    nombre="API REST (FastAPI)",
                    detalle="Autenticación y lógica de negocio",
                    estado="operativo",
                ),
                s.ServiceStatus(
                    nombre="PostgreSQL",
                    detalle="Base de datos central",
                    estado="operativo",
                ),
                s.ServiceStatus(
                    nombre="Motor de IA (Ollama + RAG)",
                    detalle=f"{ai.documentos_activos} documento(s) de conocimiento activos",
                    estado="operativo" if ai.ollama_disponible else "degradado",
                ),
                s.ServiceStatus(
                    nombre="Sincronización móvil",
                    detalle="Registros guardados sin conexion",
                    estado="operativo",
                ),
            ],
        )

    # --- dashboard ejecutivo (CU14) -------------------------------------------------

    async def dashboard(
        self, desde: date | None, hasta: date | None, etapa_id: int | None
    ) -> s.Dashboard:
        """Indicadores de los emprendimientos activos, por periodo y etapa (solo lectura)."""
        _check_period(desde, hasta)
        scope = await self._ventures.active_ventures(etapa_id)
        ids = [v.id for v in scope]
        activity = (
            await self._mentoring.activity_by_venture(ids, desde, hasta)
        ).values()
        alerts = await self._alerts.counts(ids, desde, hasta)
        start, end = period_bounds(desde, hasta)
        return s.Dashboard(
            desde=desde,
            hasta=hasta,
            etapa_id=etapa_id,
            emprendimientos_total=len(ids),
            por_etapa=[
                s.StageCount(
                    etapa_id=stage.etapa_id,
                    etapa=stage.nombre,
                    orden=stage.orden,
                    total=total,
                )
                for stage, total in await self._ventures.stage_distribution()
            ],
            sesiones=s.SessionsBlock(
                programadas=sum(a.sessions_scheduled for a in activity),
                realizadas=sum(a.sessions_done for a in activity),
                canceladas=sum(a.sessions_cancelled for a in activity),
            ),
            compromisos=s.CommitmentsBlock(
                pendientes=sum(a.commitments_pending for a in activity),
                vencidos=sum(a.commitments_overdue for a in activity),
                cumplidos_periodo=sum(a.commitments_done for a in activity),
            ),
            avances=sum(a.progress for a in activity),
            alertas=s.AlertsBlock(
                abiertas=alerts.by_state.get("abierta", 0),
                revisadas=alerts.by_state.get("revisada", 0),
                atendidas=alerts.by_state.get("atendida", 0),
                descartadas=alerts.by_state.get("descartada", 0),
                por_tipo=alerts.by_type,
            ),
            indicadores=[
                s.IndicatorSummary(
                    tipo_indicador_id=type_id,
                    nombre=name,
                    unidad=unit,
                    registros=count,
                    promedio=average,
                )
                for type_id, name, unit, count, average in await self._repo.value_summary(
                    ids, start, end
                )
            ],
        )

    # --- reportes (CU21) -------------------------------------------------------------

    async def _report_rows(
        self, kind: str, desde: date | None, hasta: date | None, etapa_id: int | None
    ) -> list[Row]:
        scope = await self._ventures.active_ventures(etapa_id)
        ids = [v.id for v in scope]
        names = {v.id: v.nombre for v in scope}
        if kind == "resumen":
            activity = await self._mentoring.activity_by_venture(ids, desde, hasta)
            open_alerts = await self._alerts.open_by_venture(ids)
            return [
                {
                    "emprendimiento": v.nombre,
                    "sector": v.sector,
                    "etapa": v.stage.nombre if v.stage else None,
                    "sesiones_realizadas": activity[v.id].sessions_done,
                    "compromisos_pendientes": activity[v.id].commitments_pending,
                    "compromisos_vencidos": activity[v.id].commitments_overdue,
                    "alertas_sin_resolver": open_alerts.get(v.id, 0),
                    "ultimo_avance": local_text(activity[v.id].last_progress),
                }
                for v in scope
            ]
        if kind == "sesiones":
            return [
                {
                    "fecha": local_text(x.fecha_realizada or x.fecha_programada),
                    "emprendimiento": x.emprendimiento,
                    "asesor": x.mentor,
                    "tema": x.tema,
                    "modalidad": x.modalidad,
                    "estado": x.estado,
                }
                for x in await self._mentoring.report_sessions(ids, desde, hasta)
            ]
        if kind == "alertas":
            return [
                {
                    "fecha": local_text(a.fecha_generacion),
                    "emprendimiento": a.emprendimiento,
                    "tipo": a.tipo,
                    "prioridad": a.prioridad,
                    "estado": a.estado,
                    "atendida_por": a.atendida_por,
                }
                for a in await self._alerts.report_alerts(ids, desde, hasta)
            ]
        start, end = period_bounds(desde, hasta)
        return [
            {
                "fecha": local_text(v.fecha_registro),
                "emprendimiento": names.get(v.emprendimiento_id),
                "indicador": t.nombre,
                "valor": float(v.valor) if v.valor is not None else None,
                "unidad": t.unidad,
                "periodo": v.periodo,
            }
            for v, t in await self._repo.value_rows(ids, start, end)
        ]

    async def report(
        self,
        kind: str,
        desde: date | None,
        hasta: date | None,
        etapa_id: int | None,
        limit: int | None = PREVIEW_LIMIT,
    ) -> s.ReportOut:
        """Reporte con vista previa (`limit` filas) o completo (`limit=None`, hasta 10 000)."""
        _check_period(desde, hasta)
        title, columns = REPORTS[kind]
        rows = await self._report_rows(kind, desde, hasta, etapa_id)
        shown = rows[: limit if limit is not None else EXPORT_LIMIT]
        return s.ReportOut(
            tipo=kind,  # type: ignore[arg-type]
            titulo=title,
            columnas=[s.ReportColumn(clave=k, etiqueta=label) for k, label in columns],
            filas=shown,
            total=len(rows),
            truncado=len(shown) < len(rows),
            desde=desde,
            hasta=hasta,
            etapa_id=etapa_id,
        )

    async def export_report(
        self,
        actor: CurrentUser,
        kind: str,
        desde: date | None,
        hasta: date | None,
        etapa_id: int | None,
    ) -> str:
        """CSV completo del reporte (mismo helper que la auditoria); la exportacion se audita."""
        out = await self.report(kind, desde, hasta, etapa_id, limit=None)
        await self._audit.record(
            actor.usuario_id,
            "negocio.reporte",
            out.titulo,
            despues={"filas": out.total, "desde": str(desde), "hasta": str(hasta)},
        )
        await self._session.commit()
        return to_csv(
            [c.etiqueta for c in out.columnas],
            ([row.get(c.clave) for c in out.columnas] for row in out.filas),
        )
