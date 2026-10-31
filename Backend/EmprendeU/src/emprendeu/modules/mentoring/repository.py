"""Acceso a datos de mentoring."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import and_, delete, func, select
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

MENTOR_ROLE = "mentor"
LEARNER_ROLE = "emprendedor"


def now() -> datetime:
    return datetime.now(UTC)


class MentoringRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

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
            .order_by(DisponibilidadMentor.dia_semana, DisponibilidadMentor.hora_inicio)
        )
        return list((await self._session.execute(stmt)).scalars().all())

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
        self, usuario_id: int, estados: list[str] | None
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
        return list((await self._session.execute(stmt)).scalars().all())

    async def list_sessions(
        self, *, estado: str | None, offset: int, limit: int
    ) -> tuple[list[SesionAcompanamiento], int]:
        cond = [SesionAcompanamiento.estado == estado] if estado else []
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
            .where(Compromiso.usuario_id == usuario_id)
            .order_by(
                Compromiso.fecha_limite.asc().nulls_last(), Compromiso.compromiso_id
            )
        )
        if estado:
            stmt = stmt.where(Compromiso.estado == estado)
        return list((await self._session.execute(stmt)).scalars().all())

    async def overdue_by_venture(self, moment: datetime) -> dict[int, int]:
        stmt = (
            select(SesionAcompanamiento.emprendimiento_id, func.count())
            .join(
                Compromiso,
                Compromiso.sesion_acompanamiento_id
                == SesionAcompanamiento.sesion_acompanamiento_id,
            )
            .where(Compromiso.estado == "pendiente", Compromiso.fecha_limite < moment)
            .group_by(SesionAcompanamiento.emprendimiento_id)
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
                            SesionAcompanamiento.emprendimiento_id,
                            func.max(Compromiso.fecha_completado),
                        )
                        .join(
                            Compromiso,
                            and_(
                                Compromiso.sesion_acompanamiento_id
                                == SesionAcompanamiento.sesion_acompanamiento_id,
                            ),
                        )
                        .group_by(SesionAcompanamiento.emprendimiento_id)
                    )
                ).all()
            ]
        )
        return out
