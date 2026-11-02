"""Acceso a datos de indicators."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import func, select
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

    async def value_summary(
        self, ids: list[int], start: datetime | None, end: datetime | None
    ) -> list[tuple[int, str, str | None, int, Decimal | None]]:
        """Por tipo de indicador: cuantos valores se registraron en el periodo y su promedio."""
        if not ids:
            return []
        stmt = (
            select(
                TipoIndicador.tipo_indicador_id,
                TipoIndicador.nombre,
                TipoIndicador.unidad,
                func.count(ValorIndicador.valor_indicador_id),
                func.avg(ValorIndicador.valor),
            )
            .join(
                ValorIndicador,
                ValorIndicador.tipo_indicador_id == TipoIndicador.tipo_indicador_id,
            )
            .where(ValorIndicador.emprendimiento_id.in_(ids))
        )
        if start is not None:
            stmt = stmt.where(ValorIndicador.fecha_registro >= start)
        if end is not None:
            stmt = stmt.where(ValorIndicador.fecha_registro < end)
        stmt = stmt.group_by(
            TipoIndicador.tipo_indicador_id, TipoIndicador.nombre, TipoIndicador.unidad
        ).order_by(TipoIndicador.nombre)
        return [
            (r[0], r[1], r[2], r[3], r[4])
            for r in (await self._session.execute(stmt)).all()
        ]

    async def value_rows(
        self,
        ids: list[int],
        start: datetime | None,
        end: datetime | None,
        limit: int = 5000,
    ) -> list[tuple[ValorIndicador, TipoIndicador]]:
        if not ids:
            return []
        stmt = (
            select(ValorIndicador, TipoIndicador)
            .join(
                TipoIndicador,
                TipoIndicador.tipo_indicador_id == ValorIndicador.tipo_indicador_id,
            )
            .where(ValorIndicador.emprendimiento_id.in_(ids))
        )
        if start is not None:
            stmt = stmt.where(ValorIndicador.fecha_registro >= start)
        if end is not None:
            stmt = stmt.where(ValorIndicador.fecha_registro < end)
        stmt = stmt.order_by(
            ValorIndicador.fecha_registro.desc(),
            ValorIndicador.valor_indicador_id.desc(),
        ).limit(limit)
        return [(r[0], r[1]) for r in (await self._session.execute(stmt)).all()]
