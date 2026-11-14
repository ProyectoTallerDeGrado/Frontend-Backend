"""Servicio de alerts: parametros, deteccion de riesgo y bandeja de alertas."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import DomainError
from emprendeu.core.pagination import PageParams
from emprendeu.core.periods import period_bounds
from emprendeu.modules.ai_assistant import AssistantService
from emprendeu.modules.alerts import schemas as s
from emprendeu.modules.alerts.exceptions import (
    AlertClosed,
    AlertNotAssigned,
    AlertNotFound,
)
from emprendeu.modules.alerts.models import Alerta, ParametroSeguimiento
from emprendeu.modules.alerts.repository import SETTING_KEYS, AlertRepository
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.gamification import GamificationService
from emprendeu.modules.mentoring import MentoringService
from emprendeu.modules.users import CurrentUser, build_user_service
from emprendeu.modules.ventures import VentureService

# Alertas cerradas: no se reabren (una nueva evaluacion puede crear otra).
CLOSED_STATES = ("atendida", "descartada")


@dataclass(frozen=True, slots=True)
class AlertCounts:
    """Alertas generadas en un periodo, por estado y por tipo."""

    by_state: dict[str, int]
    by_type: dict[str, int]


INACTIVITY = "inactividad"
SENTIMENT = "sentimiento"
OVERDUE = "compromiso_vencido"


def now() -> datetime:
    return datetime.now(UTC)


@dataclass
class _Params:
    """Parametros ya convertidos a sus tipos (la tabla guarda texto)."""

    inactividad_dias: int
    caida_sentimiento_pct: int
    periodos_consecutivos: int
    notificar_coordinador: bool
    notificar_asesor: bool
    alertar_incumplimiento: bool
    dias_limite_compromiso: int
    fecha_actualizacion: datetime | None


def _threshold(pct: int) -> str:
    """25 % de caida se guarda como umbral decimal negativo: `-0.25`."""
    return f"-{Decimal(pct) / 100:.2f}"


def _pct(threshold: str) -> int:
    return round(-Decimal(threshold) * 100)


class AlertService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = AlertRepository(session)
        self._audit = AuditService(session)
        self._ventures = VentureService(session)
        self._entrepreneurs = EntrepreneurService(session)
        self._mentoring = MentoringService(session)
        self._gamification = GamificationService(session)
        self._assistant = AssistantService(session)  # sin LLM: solo lee sentimiento
        self._users = build_user_service(session)

    # --- API publica ----------------------------------------------------------

    async def open_count(self) -> int:
        return await self._repo.count_open()

    async def counts(
        self, ids: list[int], desde: date | None, hasta: date | None
    ) -> AlertCounts:
        start, end = period_bounds(desde, hasta)
        by_state: dict[str, int] = {}
        by_type: dict[str, int] = {}
        for estado, tipo, total in await self._repo.counts(ids, start, end):
            by_state[estado or ""] = by_state.get(estado or "", 0) + total
            by_type[tipo] = by_type.get(tipo, 0) + total
        return AlertCounts(by_state, by_type)

    async def open_by_venture(self, ids: list[int]) -> dict[int, int]:
        """Alertas sin resolver (abiertas o revisadas) de cada emprendimiento."""
        return await self._repo.open_by_venture(ids)

    async def last_activity_by_venture(
        self, ids: list[int]
    ) -> dict[int, datetime | None]:
        """Última actividad relevante (mentorías, avances, retos) de cada
        emprendimiento; sin ninguna, su fecha de creación. Es la misma regla que
        la alerta de inactividad, para que el puntaje de salud no la contradiga."""
        last: dict[int, datetime] = {}
        for source in (
            await self._mentoring.last_activity_by_venture(),
            await self._gamification.last_activity_by_venture(),
        ):
            for vid, when in source.items():
                if isinstance(when, datetime) and (vid not in last or when > last[vid]):
                    last[vid] = when
        return {vid: last.get(vid) or await self._created_at(vid) for vid in ids}

    async def inactivity_days(self) -> int:
        """Días sin actividad configurados para la alerta (`dias_inactividad`)."""
        return (await self._settings()).inactividad_dias

    async def report_alerts(
        self, ids: list[int], desde: date | None, hasta: date | None
    ) -> list[s.AlertOut]:
        start, end = period_bounds(desde, hasta)
        return await self._out(await self._repo.list_for_report(ids, start, end))

    # --- parametros -----------------------------------------------------------

    async def _rows(self) -> dict[str, ParametroSeguimiento]:
        rows = await self._repo.settings()
        missing = [k for k in SETTING_KEYS if k not in rows]
        if missing:
            raise DomainError(
                "Faltan los parametros de seguimiento "
                f"({', '.join(missing)}); migraciones pendientes."
            )
        return rows

    async def _settings(self) -> _Params:
        rows = await self._rows()
        value = {k: r.valor for k, r in rows.items()}
        stamps = [r.fecha_actualizacion for r in rows.values() if r.fecha_actualizacion]
        return _Params(
            inactividad_dias=int(value["dias_inactividad"]),
            caida_sentimiento_pct=_pct(value["umbral_caida_sentimiento"]),
            periodos_consecutivos=int(value["periodos_consecutivos"]),
            notificar_coordinador=value["notificar_coordinador"] == "true",
            notificar_asesor=value["notificar_asesor"] == "true",
            alertar_incumplimiento=value["alertar_incumplimiento"] == "true",
            dias_limite_compromiso=int(value["dias_limite_compromiso"]),
            fecha_actualizacion=max(stamps) if stamps else None,
        )

    @staticmethod
    def _settings_out(p: _Params) -> s.SettingsOut:
        return s.SettingsOut(
            inactividad_dias=p.inactividad_dias,
            caida_sentimiento_pct=p.caida_sentimiento_pct,
            periodos_consecutivos=p.periodos_consecutivos,
            notificar_coordinador=p.notificar_coordinador,
            notificar_asesor=p.notificar_asesor,
            alertar_incumplimiento=p.alertar_incumplimiento,
            dias_limite_compromiso=p.dias_limite_compromiso,
            fecha_actualizacion=p.fecha_actualizacion,
        )

    async def get_settings(self) -> s.SettingsOut:
        return self._settings_out(await self._settings())

    async def update_settings(
        self, actor: CurrentUser, body: s.SettingsUpdate
    ) -> s.SettingsOut:
        rows = await self._rows()
        current = await self._settings()
        changes = body.model_dump(exclude_none=True)
        before = {k: getattr(current, k) for k in changes}
        days = body.dias_limite_compromiso or current.dias_limite_compromiso
        stored = {
            "dias_limite_compromiso": str(days),
            "dias_inactividad": str(body.inactividad_dias),
            "umbral_caida_sentimiento": _threshold(body.caida_sentimiento_pct),
            "periodos_consecutivos": str(body.periodos_consecutivos),
            "notificar_coordinador": str(body.notificar_coordinador).lower(),
            "notificar_asesor": str(body.notificar_asesor).lower(),
            "alertar_incumplimiento": str(body.alertar_incumplimiento).lower(),
        }
        moment = now()
        for key, value in stored.items():
            rows[key].valor = value
            rows[key].fecha_actualizacion = moment
            rows[key].usuario_id = actor.usuario_id
        await self._audit.record(
            actor.usuario_id,
            "config.parametros",
            f"Inactividad {body.inactividad_dias} dias · sentimiento >= "
            f"{body.caida_sentimiento_pct} % · plazo de compromisos {days} dias",
            tabla="parametros_seguimiento",
            id_registro=1,
            antes=before,
            despues=changes,
        )
        await self._repo.commit()
        return self._settings_out(await self._settings())

    # --- bandeja ---------------------------------------------------------------

    async def _out(self, rows: list[Alerta]) -> list[s.AlertOut]:
        names = await self._ventures.names_by_ids(
            sorted({r.emprendimiento_id for r in rows})
        )
        type_names = await self._repo.type_names()
        handlers = await self._users.names_by_ids(
            sorted(
                {r.atendida_por_usuario_id for r in rows if r.atendida_por_usuario_id}
            )
        )
        return [
            s.AlertOut(
                alerta_id=r.alerta_id,
                emprendimiento_id=r.emprendimiento_id,
                emprendimiento=names.get(r.emprendimiento_id),
                tipo=type_names.get(r.tipo_alerta_id),
                titulo=r.titulo,
                descripcion=r.descripcion,
                prioridad=r.prioridad,
                estado=r.estado,
                fecha_generacion=r.fecha_generacion,
                atendida_por_id=r.atendida_por_usuario_id,
                atendida_por=handlers.get(r.atendida_por_usuario_id or -1),
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

    async def _ensure_assigned(
        self, actor: CurrentUser, emprendimiento_id: int
    ) -> None:
        """Un asesor solo ve y gestiona alertas de los emprendimientos que tiene asignados."""
        if actor.rol != "asesor":
            return
        assigned = [
            a.emprendimiento_id
            for a in await self._mentoring.list_assignments(actor.usuario_id, None)
            if a.estado == "activa"
        ]
        if emprendimiento_id not in assigned:
            raise AlertNotAssigned

    async def get(self, actor: CurrentUser, alerta_id: int) -> s.AlertOut:
        """Detalle de una alerta: emprendimiento, motivo, fecha y estado (CU13)."""
        alert = await self._repo.get(alerta_id)
        if alert is None:
            raise AlertNotFound
        await self._ensure_assigned(actor, alert.emprendimiento_id)
        return (await self._out([alert]))[0]

    async def update(
        self, actor: CurrentUser, alerta_id: int, body: s.AlertUpdate
    ) -> s.AlertOut:
        """Marca una alerta como revisada, atendida o descartada (CU13)."""
        alert = await self._repo.get(alerta_id)
        if alert is None:
            raise AlertNotFound
        await self._ensure_assigned(actor, alert.emprendimiento_id)
        if alert.estado in CLOSED_STATES:
            raise AlertClosed
        before = alert.estado
        if before != body.estado:
            alert.estado = body.estado
            if body.estado == "atendida":
                alert.atendida_por_usuario_id = actor.usuario_id
            await self._audit.record(
                actor.usuario_id,
                "negocio.alerta",
                alert.titulo,
                tabla="alertas",
                id_registro=alerta_id,
                antes={"estado": before},
                despues={"estado": body.estado},
            )
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
        limit = timedelta(days=settings.inactividad_dias)
        venture_ids = await self._ventures.active_venture_ids()
        last = await self.last_activity_by_venture(venture_ids)
        for vid in venture_ids:
            reference = last.get(vid)
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
