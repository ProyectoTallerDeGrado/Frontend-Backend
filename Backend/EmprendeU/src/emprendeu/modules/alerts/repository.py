"""Acceso a datos de alerts."""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.alerts.models import Alerta, ParametroSeguimiento, TipoAlerta

SETTINGS_ID = 1


class AlertRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def add(self, obj: object) -> None:
        self._session.add(obj)
        await self._session.flush()

    async def settings(self) -> ParametroSeguimiento | None:
        return await self._session.get(ParametroSeguimiento, SETTINGS_ID)

    async def type_by_name(self, name: str) -> TipoAlerta | None:
        stmt = select(TipoAlerta).where(TipoAlerta.nombre == name)
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def get(self, alerta_id: int) -> Alerta | None:
        return await self._session.get(Alerta, alerta_id)

    async def list(
        self,
        *,
        estado: str | None,
        tipo: str | None,
        venture_ids: list[int] | None,
        offset: int,
        limit: int,
    ) -> tuple[list[Alerta], int]:
        cond = []
        if estado:
            cond.append(Alerta.estado == estado)
        if tipo:
            cond.append(Alerta.tipo == tipo)
        if venture_ids is not None:
            cond.append(Alerta.emprendimiento_id.in_(venture_ids))
        total = (
            await self._session.execute(
                select(func.count()).select_from(Alerta).where(*cond)
            )
        ).scalar_one()
        stmt = (
            select(Alerta)
            .where(*cond)
            .order_by(Alerta.fecha_generacion.desc(), Alerta.alerta_id.desc())
            .offset(offset)
            .limit(limit)
        )
        return list((await self._session.execute(stmt)).scalars().all()), total

    async def open_keys(self) -> set[tuple[int, str]]:
        """`(emprendimiento, tipo)` con alerta abierta (evita duplicados)."""
        stmt = select(Alerta.emprendimiento_id, Alerta.tipo).where(
            Alerta.estado == "abierta"
        )
        return {(r[0], r[1]) for r in (await self._session.execute(stmt)).all()}

    async def count_open(self) -> int:
        return (
            await self._session.execute(
                select(func.count())
                .select_from(Alerta)
                .where(Alerta.estado == "abierta")
            )
        ).scalar_one()
