"""Acceso a datos de training."""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.training.models import Capacitacion, CapacitacionParticipante


class TrainingRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def add(self, obj: object) -> None:
        self._session.add(obj)
        await self._session.flush()

    async def get(self, capacitacion_id: int) -> Capacitacion | None:
        return await self._session.get(Capacitacion, capacitacion_id)

    async def list(
        self, *, estado: str | None, offset: int, limit: int
    ) -> tuple[list[tuple[Capacitacion, int]], int]:
        cond = [Capacitacion.estado == estado] if estado else []
        total = (
            await self._session.execute(
                select(func.count()).select_from(Capacitacion).where(*cond)
            )
        ).scalar_one()
        stmt = (
            select(
                Capacitacion,
                func.count(CapacitacionParticipante.capacitacion_participante_id),
            )
            .outerjoin(
                CapacitacionParticipante,
                CapacitacionParticipante.capacitacion_id
                == Capacitacion.capacitacion_id,
            )
            .where(*cond)
            .group_by(Capacitacion.capacitacion_id)
            .order_by(
                Capacitacion.fecha.desc().nulls_last(),
                Capacitacion.capacitacion_id.desc(),
            )
            .offset(offset)
            .limit(limit)
        )
        return [
            (r[0], int(r[1])) for r in (await self._session.execute(stmt)).all()
        ], total

    async def count_participants(self, capacitacion_id: int) -> int:
        return (
            await self._session.execute(
                select(func.count())
                .select_from(CapacitacionParticipante)
                .where(CapacitacionParticipante.capacitacion_id == capacitacion_id)
            )
        ).scalar_one()

    async def participants(
        self, capacitacion_id: int
    ) -> list[CapacitacionParticipante]:
        stmt = (
            select(CapacitacionParticipante)
            .where(CapacitacionParticipante.capacitacion_id == capacitacion_id)
            .order_by(CapacitacionParticipante.capacitacion_participante_id)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def participant(
        self, capacitacion_id: int, emprendedor_id: int
    ) -> CapacitacionParticipante | None:
        stmt = select(CapacitacionParticipante).where(
            CapacitacionParticipante.capacitacion_id == capacitacion_id,
            CapacitacionParticipante.emprendedor_id == emprendedor_id,
        )
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def for_entrepreneur(
        self, emprendedor_id: int
    ) -> list[tuple[Capacitacion, int, bool | None]]:
        stmt = (
            select(Capacitacion, CapacitacionParticipante.asistencia)
            .join(
                CapacitacionParticipante,
                CapacitacionParticipante.capacitacion_id
                == Capacitacion.capacitacion_id,
            )
            .where(CapacitacionParticipante.emprendedor_id == emprendedor_id)
            .order_by(Capacitacion.fecha.desc().nulls_last())
        )
        rows = (await self._session.execute(stmt)).all()
        return [
            (r[0], await self.count_participants(r[0].capacitacion_id), r[1])
            for r in rows
        ]
