"""Acceso a datos de mentoring."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import column, delete, func, select, table
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.mentoring.models import (
    Asignacion,
    Compromiso,
    DisponibilidadMentor,
    PerfilMentor,
    Recomendacion,
    Seguimiento,
    SesionAcompanamiento,
    SesionParticipante,
    Tipo,
)

# Tabla de `alerts` que se lee solo para un valor (la convencion de fronteras del
# proyecto pide `sqlalchemy.table` y no importar el modelo de otro modulo).
_PARAMS = table(
    "parametros_seguimiento", column("clave"), column("valor"), schema="cieu"
)
DEFAULT_COMMITMENT_DAYS = 7

MENTOR_ROLE = "mentor"
LEARNER_ROLE = "emprendedor"


def now() -> datetime:
    return datetime.now(UTC)


def _effective_date():  # type: ignore[no-untyped-def]
    """Cuando ocurrio la sesion: la fecha realizada si existe, si no la programada."""
    return func.coalesce(
        SesionAcompanamiento.fecha_realizada, SesionAcompanamiento.fecha_programada
    )


class MentoringRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def rollback(self) -> None:
        await self._session.rollback()

    async def add(self, obj: object) -> None:
        self._session.add(obj)
        await self._session.flush()

    # --- catalogo / mentores ---------------------------------------------------

    async def tipo_by_name(self, name: str) -> Tipo | None:
        stmt = select(Tipo).where(Tipo.nombre == name)
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def profiles(self) -> dict[int, PerfilMentor]:
        rows = (await self._session.execute(select(PerfilMentor))).scalars().all()
        return {r.usuario_id: r for r in rows}

    async def profile(self, usuario_id: int) -> PerfilMentor | None:
        stmt = select(PerfilMentor).where(PerfilMentor.usuario_id == usuario_id)
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def availability(self, usuario_id: int) -> list[DisponibilidadMentor]:
        stmt = (
            select(DisponibilidadMentor)
            .where(DisponibilidadMentor.usuario_id == usuario_id)
            .order_by(DisponibilidadMentor.fecha_inicio)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def open_availability_between(
        self, usuario_id: int, start: datetime, end: datetime
    ) -> list[DisponibilidadMentor]:
        """Intervalos `disponible` que tocan `[start, end)`."""
        stmt = (
            select(DisponibilidadMentor)
            .where(
                DisponibilidadMentor.usuario_id == usuario_id,
                DisponibilidadMentor.estado == "disponible",
                DisponibilidadMentor.fecha_inicio < end,
                DisponibilidadMentor.fecha_fin > start,
            )
            .order_by(DisponibilidadMentor.fecha_inicio)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def get_availability_row(
        self, disponibilidad_id: int
    ) -> DisponibilidadMentor | None:
        return await self._session.get(DisponibilidadMentor, disponibilidad_id)

    async def delete_availability_row(self, row: DisponibilidadMentor) -> None:
        await self._session.delete(row)
        await self._session.flush()

    async def replace_availability(
        self, usuario_id: int, items: list[DisponibilidadMentor]
    ) -> None:
        await self._session.execute(
            delete(DisponibilidadMentor).where(
                DisponibilidadMentor.usuario_id == usuario_id
            )
        )
        self._session.add_all(items)
        await self._session.flush()

    # --- sesiones --------------------------------------------------------------

    async def get_session(self, sesion_id: int) -> SesionAcompanamiento | None:
        return await self._session.get(SesionAcompanamiento, sesion_id)

    async def participants(
        self, sesion_ids: list[int]
    ) -> dict[int, list[SesionParticipante]]:
        if not sesion_ids:
            return {}
        stmt = select(SesionParticipante).where(
            SesionParticipante.sesion_acompanamiento_id.in_(sesion_ids)
        )
        out: dict[int, list[SesionParticipante]] = {i: [] for i in sesion_ids}
        for p in (await self._session.execute(stmt)).scalars().all():
            out[p.sesion_acompanamiento_id].append(p)
        return out

    async def counts(self, sesion_ids: list[int]) -> dict[int, tuple[int, int]]:
        """`{sesion: (recomendaciones, compromisos)}`."""
        if not sesion_ids:
            return {}
        recs = dict(
            (
                await self._session.execute(
                    select(Recomendacion.sesion_acompanamiento_id, func.count())
                    .where(Recomendacion.sesion_acompanamiento_id.in_(sesion_ids))
                    .group_by(Recomendacion.sesion_acompanamiento_id)
                )
            ).all()
        )
        coms = dict(
            (
                await self._session.execute(
                    select(Compromiso.sesion_acompanamiento_id, func.count())
                    .where(Compromiso.sesion_acompanamiento_id.in_(sesion_ids))
                    .group_by(Compromiso.sesion_acompanamiento_id)
                )
            ).all()
        )
        return {i: (recs.get(i, 0), coms.get(i, 0)) for i in sesion_ids}

    async def mentor_sessions_between(
        self, mentor_id: int, start: datetime, end: datetime
    ) -> list[SesionAcompanamiento]:
        stmt = (
            select(SesionAcompanamiento)
            .join(
                SesionParticipante,
                SesionParticipante.sesion_acompanamiento_id
                == SesionAcompanamiento.sesion_acompanamiento_id,
            )
            .where(
                SesionParticipante.usuario_id == mentor_id,
                SesionParticipante.rol_participante == MENTOR_ROLE,
                SesionAcompanamiento.estado == "programada",
                SesionAcompanamiento.fecha_programada >= start,
                SesionAcompanamiento.fecha_programada < end,
            )
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def sessions_for_user(
        self,
        usuario_id: int,
        estados: list[str] | None,
        desde: datetime | None = None,
        hasta: datetime | None = None,
    ) -> list[SesionAcompanamiento]:
        stmt = (
            select(SesionAcompanamiento)
            .join(
                SesionParticipante,
                SesionParticipante.sesion_acompanamiento_id
                == SesionAcompanamiento.sesion_acompanamiento_id,
            )
            .where(SesionParticipante.usuario_id == usuario_id)
            .order_by(SesionAcompanamiento.fecha_programada.desc())
        )
        if estados:
            stmt = stmt.where(SesionAcompanamiento.estado.in_(estados))
        if desde is not None:
            stmt = stmt.where(_effective_date() >= desde)
        if hasta is not None:
            stmt = stmt.where(_effective_date() < hasta)
        return list((await self._session.execute(stmt)).scalars().all())

    async def list_sessions(
        self,
        *,
        estado: str | None,
        desde: datetime | None = None,
        hasta: datetime | None = None,
        emprendimiento_id: int | None = None,
        offset: int,
        limit: int,
    ) -> tuple[list[SesionAcompanamiento], int]:
        cond = [SesionAcompanamiento.estado == estado] if estado else []
        if desde is not None:
            cond.append(_effective_date() >= desde)
        if hasta is not None:
            cond.append(_effective_date() < hasta)
        if emprendimiento_id is not None:
            cond.append(SesionAcompanamiento.emprendimiento_id == emprendimiento_id)
        total = (
            await self._session.execute(
                select(func.count()).select_from(SesionAcompanamiento).where(*cond)
            )
        ).scalar_one()
        stmt = (
            select(SesionAcompanamiento)
            .where(*cond)
            .order_by(SesionAcompanamiento.fecha_programada.desc())
            .offset(offset)
            .limit(limit)
        )
        return list((await self._session.execute(stmt)).scalars().all()), total

    # --- compromisos -----------------------------------------------------------

    async def get_commitment(self, compromiso_id: int) -> Compromiso | None:
        return await self._session.get(Compromiso, compromiso_id)

    async def commitments_for_user(
        self, usuario_id: int, estado: str | None
    ) -> list[Compromiso]:
        stmt = (
            select(Compromiso)
            .where(Compromiso.responsable_usuario_id == usuario_id)
            .order_by(
                Compromiso.fecha_limite.asc().nulls_last(), Compromiso.compromiso_id
            )
        )
        if estado:
            stmt = stmt.where(Compromiso.estado == estado)
        return list((await self._session.execute(stmt)).scalars().all())

    async def overdue_by_venture(self, moment: datetime) -> dict[int, int]:
        stmt = (
            select(Compromiso.emprendimiento_id, func.count())
            .where(Compromiso.estado == "pendiente", Compromiso.fecha_limite < moment)
            .group_by(Compromiso.emprendimiento_id)
        )
        return {r[0]: r[1] for r in (await self._session.execute(stmt)).all()}

    # --- recomendaciones -------------------------------------------------------

    async def recommendations_for_ventures(self, ids: list[int]) -> list[Recomendacion]:
        if not ids:
            return []
        stmt = (
            select(Recomendacion)
            .where(Recomendacion.emprendimiento_id.in_(ids))
            .order_by(Recomendacion.fecha.desc())
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def commitments_of_venture(self, emprendimiento_id: int) -> list[Compromiso]:
        stmt = select(Compromiso).where(
            Compromiso.emprendimiento_id == emprendimiento_id
        )
        return list((await self._session.execute(stmt)).scalars().all())

    # --- seguimientos ----------------------------------------------------------

    async def progress_by_ref(self, usuario_id: int, ref: str) -> Seguimiento | None:
        stmt = select(Seguimiento).where(
            Seguimiento.usuario_id == usuario_id, Seguimiento.referencia_cliente == ref
        )
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def progress_for_venture(
        self, emprendimiento_id: int, limit: int
    ) -> list[Seguimiento]:
        stmt = (
            select(Seguimiento)
            .where(Seguimiento.emprendimiento_id == emprendimiento_id)
            .order_by(Seguimiento.fecha.desc(), Seguimiento.seguimiento_id.desc())
            .limit(limit)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def progress_dates(self, usuario_id: int, since: datetime) -> list[datetime]:
        stmt = select(Seguimiento.fecha).where(
            Seguimiento.usuario_id == usuario_id, Seguimiento.fecha >= since
        )
        return [d for d in (await self._session.execute(stmt)).scalars().all() if d]

    # --- asignaciones ----------------------------------------------------------

    async def get_assignment(self, asignacion_id: int) -> Asignacion | None:
        return await self._session.get(Asignacion, asignacion_id)

    async def list_assignments(
        self, *, usuario_id: int | None, emprendimiento_id: int | None
    ) -> list[Asignacion]:
        stmt = select(Asignacion).order_by(Asignacion.asignacion_id.desc())
        if usuario_id is not None:
            stmt = stmt.where(Asignacion.usuario_id == usuario_id)
        if emprendimiento_id is not None:
            stmt = stmt.where(Asignacion.emprendimiento_id == emprendimiento_id)
        return list((await self._session.execute(stmt)).scalars().all())

    async def active_assignment(
        self, usuario_id: int, emprendimiento_id: int
    ) -> Asignacion | None:
        stmt = select(Asignacion).where(
            Asignacion.usuario_id == usuario_id,
            Asignacion.emprendimiento_id == emprendimiento_id,
            Asignacion.estado == "activa",
        )
        return (await self._session.execute(stmt)).scalars().first()

    async def assigned_mentor_ids(self, emprendimiento_id: int) -> list[int]:
        stmt = select(Asignacion.usuario_id).where(
            Asignacion.emprendimiento_id == emprendimiento_id,
            Asignacion.estado == "activa",
        )
        return sorted(set((await self._session.execute(stmt)).scalars().all()))

    async def commitment_days(self) -> int:
        stmt = select(_PARAMS.c.valor).where(
            _PARAMS.c.clave == "dias_limite_compromiso"
        )
        raw = (await self._session.execute(stmt)).scalar_one_or_none()
        try:
            days = int(raw) if raw is not None else DEFAULT_COMMITMENT_DAYS
        except ValueError:
            return DEFAULT_COMMITMENT_DAYS
        return days if days > 0 else DEFAULT_COMMITMENT_DAYS

    # --- resumenes por emprendimiento (dashboard y reportes) ------------------

    async def session_counts(
        self, ids: list[int], start: datetime | None, end: datetime | None
    ) -> dict[int, dict[str, int]]:
        if not ids:
            return {}
        stmt = select(
            SesionAcompanamiento.emprendimiento_id,
            SesionAcompanamiento.estado,
            func.count(),
        ).where(SesionAcompanamiento.emprendimiento_id.in_(ids))
        if start is not None:
            stmt = stmt.where(_effective_date() >= start)
        if end is not None:
            stmt = stmt.where(_effective_date() < end)
        stmt = stmt.group_by(
            SesionAcompanamiento.emprendimiento_id, SesionAcompanamiento.estado
        )
        out: dict[int, dict[str, int]] = {}
        for venture_id, estado, total in (await self._session.execute(stmt)).all():
            out.setdefault(venture_id, {})[estado or ""] = total
        return out

    async def commitment_counts(
        self,
        ids: list[int],
        start: datetime | None,
        end: datetime | None,
        moment: datetime,
    ) -> dict[int, dict[str, int]]:
        """Por emprendimiento: pendientes y vencidos (hoy) y cumplidos en el periodo."""
        if not ids:
            return {}
        out: dict[int, dict[str, int]] = {}

        async def run(key: str, *conditions: object) -> None:
            stmt = (
                select(Compromiso.emprendimiento_id, func.count())
                .where(Compromiso.emprendimiento_id.in_(ids), *conditions)
                .group_by(Compromiso.emprendimiento_id)
            )
            for venture_id, total in (await self._session.execute(stmt)).all():
                out.setdefault(venture_id, {})[key] = total

        await run("pendientes", Compromiso.estado == "pendiente")
        await run(
            "vencidos",
            Compromiso.estado == "pendiente",
            Compromiso.fecha_limite < moment,
        )
        done: list[object] = [Compromiso.estado == "cumplido"]
        if start is not None:
            done.append(Compromiso.fecha_completado >= start)
        if end is not None:
            done.append(Compromiso.fecha_completado < end)
        await run("cumplidos", *done)
        return out

    async def progress_stats(
        self, ids: list[int], start: datetime | None, end: datetime | None
    ) -> tuple[dict[int, int], dict[int, datetime]]:
        """Avances registrados en el periodo y fecha del ultimo avance de cada uno."""
        if not ids:
            return {}, {}
        in_period = select(Seguimiento.emprendimiento_id, func.count()).where(
            Seguimiento.emprendimiento_id.in_(ids)
        )
        if start is not None:
            in_period = in_period.where(Seguimiento.fecha >= start)
        if end is not None:
            in_period = in_period.where(Seguimiento.fecha < end)
        counts = {
            r[0]: r[1]
            for r in (
                await self._session.execute(
                    in_period.group_by(Seguimiento.emprendimiento_id)
                )
            ).all()
        }
        last_stmt = (
            select(Seguimiento.emprendimiento_id, func.max(Seguimiento.fecha))
            .where(Seguimiento.emprendimiento_id.in_(ids))
            .group_by(Seguimiento.emprendimiento_id)
        )
        last = {
            r[0]: r[1] for r in (await self._session.execute(last_stmt)).all() if r[1]
        }
        return counts, last

    async def sessions_of_ventures(
        self,
        ids: list[int],
        start: datetime | None,
        end: datetime | None,
        limit: int = 5000,
    ) -> list[SesionAcompanamiento]:
        if not ids:
            return []
        stmt = select(SesionAcompanamiento).where(
            SesionAcompanamiento.emprendimiento_id.in_(ids)
        )
        if start is not None:
            stmt = stmt.where(_effective_date() >= start)
        if end is not None:
            stmt = stmt.where(_effective_date() < end)
        stmt = stmt.order_by(_effective_date().desc()).limit(limit)
        return list((await self._session.execute(stmt)).scalars().all())

    # --- actividad (alertas) ---------------------------------------------------

    async def last_activity_by_venture(self) -> dict[int, datetime]:
        out: dict[int, datetime] = {}

        def merge(rows: list[tuple[int, datetime | None]]) -> None:
            for vid, when in rows:
                if when and (vid not in out or when > out[vid]):
                    out[vid] = when

        merge(
            [
                (r[0], r[1])
                for r in (
                    await self._session.execute(
                        select(
                            Seguimiento.emprendimiento_id, func.max(Seguimiento.fecha)
                        ).group_by(Seguimiento.emprendimiento_id)
                    )
                ).all()
            ]
        )
        merge(
            [
                (r[0], r[1])
                for r in (
                    await self._session.execute(
                        select(
                            SesionAcompanamiento.emprendimiento_id,
                            func.max(SesionAcompanamiento.fecha_realizada),
                        ).group_by(SesionAcompanamiento.emprendimiento_id)
                    )
                ).all()
            ]
        )
        merge(
            [
                (r[0], r[1])
                for r in (
                    await self._session.execute(
                        select(
                            Compromiso.emprendimiento_id,
                            func.max(Compromiso.fecha_completado),
                        ).group_by(Compromiso.emprendimiento_id)
                    )
                ).all()
            ]
        )
        return out
