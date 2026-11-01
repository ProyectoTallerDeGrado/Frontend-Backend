"""Acceso a datos de indicators."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.indicators.models import TipoIndicador, ValorIndicador


class IndicatorRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def add(self, obj: object) -> None:
        self._session.add(obj)
        await self._session.flush()

    async def list_types(self) -> list[TipoIndicador]:
        stmt = select(TipoIndicador).order_by(TipoIndicador.nombre)
        return list((await self._session.execute(stmt)).scalars().all())

    async def get_type(self, type_id: int) -> TipoIndicador | None:
        return await self._session.get(TipoIndicador, type_id)

    async def values(
        self, emprendimiento_id: int
    ) -> list[tuple[ValorIndicador, TipoIndicador]]:
        stmt = (
            select(ValorIndicador, TipoIndicador)
            .join(
                TipoIndicador,
                TipoIndicador.tipo_indicador_id == ValorIndicador.tipo_indicador_id,
            )
            .where(ValorIndicador.emprendimiento_id == emprendimiento_id)
            .order_by(
                ValorIndicador.fecha_registro.desc(),
                ValorIndicador.valor_indicador_id.desc(),
            )
        )
        return [(r[0], r[1]) for r in (await self._session.execute(stmt)).all()]
