"""Servicio de alerts: parametros, deteccion de riesgo y bandeja de alertas."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import DomainError
from emprendeu.core.pagination import PageParams
from emprendeu.modules.ai_assistant import AssistantService
from emprendeu.modules.alerts import schemas as s
from emprendeu.modules.alerts.exceptions import AlertNotFound
from emprendeu.modules.alerts.models import Alerta, ParametroSeguimiento
from emprendeu.modules.alerts.repository import AlertRepository
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.gamification import GamificationService
from emprendeu.modules.mentoring import MentoringService
from emprendeu.modules.users import CurrentUser
from emprendeu.modules.ventures import VentureService

INACTIVITY = "inactividad"
SENTIMENT = "sentimiento"
OVERDUE = "compromiso_vencido"


def now() -> datetime:
    return datetime.now(UTC)


class AlertService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = AlertRepository(session)
        self._audit = AuditService(session)
        self._ventures = VentureService(session)
        self._entrepreneurs = EntrepreneurService(session)
        self._mentoring = MentoringService(session)
        self._gamification = GamificationService(session)
        self._assistant = AssistantService(session)  # sin LLM: solo lee sentimiento

    # --- API publica ----------------------------------------------------------

    async def open_count(self) -> int:
        return await self._repo.count_open()

    # --- parametros -----------------------------------------------------------

    async def _settings(self) -> ParametroSeguimiento:
        found = await self._repo.settings()
        if found is None:
            raise DomainError(
                "Faltan los parametros de seguimiento (migraciones pendientes)."
            )
        return found

    @staticmethod
    def _settings_out(p: ParametroSeguimiento) -> s.SettingsOut:
        return s.SettingsOut(
            inactividad_dias=p.inactividad_dias,
            caida_sentimiento_pct=p.caida_sentimiento_pct,
            periodos_consecutivos=p.periodos_consecutivos,
            notificar_coordinador=p.notificar_coordinador,
            notificar_asesor=p.notificar_asesor,
            alertar_incumplimiento=p.alertar_incumplimiento,
            fecha_actualizacion=p.fecha_actualizacion,
        )

    async def get_settings(self) -> s.SettingsOut:
        return self._settings_out(await self._settings())

    async def update_settings(
        self, actor: CurrentUser, body: s.SettingsUpdate
    ) -> s.SettingsOut:
        current = await self._settings()
        changes = body.model_dump()
        before = {k: getattr(current, k) for k in changes}
        for key, value in changes.items():
            setattr(current, key, value)
        current.fecha_actualizacion = now()
        current.usuario_id = actor.usuario_id
        await self._audit.record(
            actor.usuario_id,
            "config.parametros",
            f"Inactividad {body.inactividad_dias} dias · sentimiento >= "
            f"{body.caida_sentimiento_pct} %",
            tabla="parametros_seguimiento",
            id_registro=1,
            antes=before,
            despues=changes,
        )
        await self._repo.commit()
        return self._settings_out(current)

    # --- bandeja ---------------------------------------------------------------

    async def _out(self, rows: list[Alerta]) -> list[s.AlertOut]:
        names = await self._ventures.names_by_ids(
            sorted({r.emprendimiento_id for r in rows})
        )
        return [
            s.AlertOut(
                alerta_id=r.alerta_id,
                emprendimiento_id=r.emprendimiento_id,
                emprendimiento=names.get(r.emprendimiento_id),
                tipo=r.tipo,
                titulo=r.titulo,
                descripcion=r.descripcion,
                prioridad=r.prioridad,
                estado=r.estado,
                fecha_generacion=r.fecha_generacion,
            )
            for r in rows
        ]

    async def list(
        self,
        user: CurrentUser,
        params: PageParams,
        estado: str | None,
        tipo: str | None,
    ) -> tuple[list[s.AlertOut], int]:
        settings = await self._settings()
        venture_ids: list[int] | None = None
        if user.rol == "coordinador" and not settings.notificar_coordinador:
            return [], 0
        if user.rol == "asesor":
            if not settings.notificar_asesor:
                return [], 0
            assigned = await self._mentoring.list_assignments(user.usuario_id, None)
            venture_ids = [
                a.emprendimiento_id for a in assigned if a.estado == "activa"
            ]
            if not venture_ids:
                return [], 0
        rows, total = await self._repo.list(
            estado=estado,
            tipo=tipo,
            venture_ids=venture_ids,
            offset=params.offset,
            limit=params.page_size,
        )
        return await self._out(rows), total

    async def update(
        self, actor: CurrentUser, alerta_id: int, body: s.AlertUpdate
    ) -> s.AlertOut:
        alert = await self._repo.get(alerta_id)
        if alert is None:
            raise AlertNotFound
        alert.estado = body.estado
        await self._repo.commit()
        return (await self._out([alert]))[0]

    # --- deteccion -------------------------------------------------------------

    async def _raise(
        self,
        found: dict[str, int],
        existing: set[tuple[int, str]],
        venture_id: int,
        kind: str,
        title: str,
        description: str,
        priority: str,
    ) -> None:
        if (venture_id, kind) in existing:
            return
        tipo = await self._repo.type_by_name(kind)
        if tipo is None:
            raise DomainError(
                f"Falta el tipo de alerta {kind} (migraciones pendientes)."
            )
        await self._repo.add(
            Alerta(
                emprendimiento_id=venture_id,
                tipo_alerta_id=tipo.tipo_alerta_id,
                tipo=kind,
                titulo=title,
                descripcion=description,
                prioridad=priority,
                estado="abierta",
                fecha_generacion=now(),
            )
        )
        existing.add((venture_id, kind))
        found[kind] = found.get(kind, 0) + 1

    async def evaluate(self, actor_id: int | None = None) -> s.EvaluationResult:
        """Detecta riesgo de desercion y crea alertas (sin cambiar el emprendimiento)."""
        settings = await self._settings()
        existing = await self._repo.open_keys()
        found: dict[str, int] = {}
        moment = now()

        # 1) inactividad
        last: dict[int, datetime] = {}
        for source in (
            await self._mentoring.last_activity_by_venture(),
            await self._gamification.last_activity_by_venture(),
        ):
            for vid, when in source.items():
                if isinstance(when, datetime) and (vid not in last or when > last[vid]):
                    last[vid] = when
        limit = timedelta(days=settings.inactividad_dias)
        for vid in await self._ventures.active_venture_ids():
            reference = last.get(vid) or await self._created_at(vid)
            if reference is None or moment - reference <= limit:
                continue
            idle = (moment - reference).days
            await self._raise(
                found,
                existing,
                vid,
                INACTIVITY,
                "Emprendimiento sin actividad",
                f"Sin actividad relevante hace {idle} dias "
                f"(limite configurado: {settings.inactividad_dias}).",
                "alta" if idle >= 2 * settings.inactividad_dias else "media",
            )

        # 2) sentimiento
        for eid in await self._assistant.sentiment_drops(
            settings.caida_sentimiento_pct, settings.periodos_consecutivos
        ):
            for vid in await self._entrepreneurs.venture_ids_of_entrepreneur(eid):
                await self._raise(
                    found,
                    existing,
                    vid,
                    SENTIMENT,
                    "Caida sostenida del indice de sentimiento",
                    f"{settings.periodos_consecutivos} periodos consecutivos con caida de al "
                    f"menos {settings.caida_sentimiento_pct} %. Es una senal complementaria, "
                    "no un diagnostico.",
                    "alta",
                )

        # 3) compromisos vencidos
        if settings.alertar_incumplimiento:
            for vid, total in (await self._mentoring.overdue_by_venture()).items():
                await self._raise(
                    found,
                    existing,
                    vid,
                    OVERDUE,
                    "Compromisos vencidos sin avance",
                    f"Hay {total} compromiso(s) vencido(s) sin cumplir.",
                    "media",
                )

        if found:
            await self._audit.record(
                actor_id,
                "config.parametros",
                "Evaluacion de alertas",
                despues={"creadas": found},
            )
        await self._repo.commit()
        return s.EvaluationResult(creadas=sum(found.values()), por_tipo=found)

    async def _created_at(self, venture_id: int) -> datetime | None:
        return await self._ventures.created_at(venture_id)
