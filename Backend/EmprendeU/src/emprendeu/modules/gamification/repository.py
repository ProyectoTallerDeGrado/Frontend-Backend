"""Acceso a datos de gamification."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.gamification.models import (
    EmprendedorInsignia,
    EmprendimientoReto,
    Insignia,
    MovimientoXp,
    Reto,
)


def now() -> datetime:
    return datetime.now(UTC)


class GamificationRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def add(self, obj: object) -> None:
        self._session.add(obj)
        await self._session.flush()

    # --- retos -------------------------------------------------------------

    async def list_challenges(self, *, only_active: bool = False) -> list[Reto]:
        stmt = select(Reto).order_by(Reto.orden.asc().nulls_last(), Reto.reto_id)
        if only_active:
            stmt = stmt.where(Reto.estado == "activo")
        return list((await self._session.execute(stmt)).scalars().all())

    async def get_challenge(self, reto_id: int) -> Reto | None:
        return await self._session.get(Reto, reto_id)

    async def venture_challenges(
        self, emprendimiento_id: int
    ) -> dict[int, EmprendimientoReto]:
        stmt = select(EmprendimientoReto).where(
            EmprendimientoReto.emprendimiento_id == emprendimiento_id
        )
        rows = (await self._session.execute(stmt)).scalars().all()
        return {r.reto_id: r for r in rows}

    async def max_order(self) -> int:
        return (
            await self._session.execute(select(func.coalesce(func.max(Reto.orden), 0)))
        ).scalar_one()

    # --- insignias ---------------------------------------------------------

    async def list_badges(self) -> list[Insignia]:
        stmt = select(Insignia).order_by(Insignia.insignia_id)
        return list((await self._session.execute(stmt)).scalars().all())

    async def get_badge(self, insignia_id: int) -> Insignia | None:
        return await self._session.get(Insignia, insignia_id)

    async def earned_badges(self, emprendedor_id: int) -> dict[int, datetime | None]:
        stmt = select(
            EmprendedorInsignia.insignia_id, EmprendedorInsignia.fecha_obtenida
        ).where(EmprendedorInsignia.emprendedor_id == emprendedor_id)
        return {r[0]: r[1] for r in (await self._session.execute(stmt)).all()}

    # --- xp ----------------------------------------------------------------

    async def xp_total(self, emprendedor_id: int) -> int:
        stmt = select(func.coalesce(func.sum(MovimientoXp.cantidad), 0)).where(
            MovimientoXp.emprendedor_id == emprendedor_id
        )
        return int((await self._session.execute(stmt)).scalar_one())

    async def history(self, emprendedor_id: int, limit: int) -> list[MovimientoXp]:
        stmt = (
            select(MovimientoXp)
            .where(MovimientoXp.emprendedor_id == emprendedor_id)
            .order_by(MovimientoXp.fecha.desc(), MovimientoXp.movimiento_xp_id.desc())
            .limit(limit)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def last_completion_by_venture(self) -> dict[int, datetime]:
        stmt = (
            select(
                EmprendimientoReto.emprendimiento_id,
                func.max(EmprendimientoReto.fecha_completado),
            )
            .where(EmprendimientoReto.fecha_completado.is_not(None))
            .group_by(EmprendimientoReto.emprendimiento_id)
        )
        return {r[0]: r[1] for r in (await self._session.execute(stmt)).all()}
