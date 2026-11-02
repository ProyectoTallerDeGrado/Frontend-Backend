"""Acceso a datos de alerts."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.alerts.models import Alerta, ParametroSeguimiento, TipoAlerta

# Claves de `parametros_seguimiento`. Las tres primeras vienen del esquema de
# referencia; el resto conserva los ajustes que ya tenia el panel.
# Estados en que una alerta sigue sin resolver (una `revisada` no se duplica al evaluar).
OPEN_STATES = ("abierta", "revisada")

SETTING_KEYS = (
    "dias_inactividad",
    "umbral_caida_sentimiento",
    "dias_limite_compromiso",
    "periodos_consecutivos",
    "notificar_coordinador",
    "notificar_asesor",
    "alertar_incumplimiento",
)


class AlertRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def add(self, obj: object) -> None:
        self._session.add(obj)
        await self._session.flush()

    async def settings(self) -> dict[str, ParametroSeguimiento]:
        rows = (await self._session.execute(select(ParametroSeguimiento))).scalars()
        return {r.clave: r for r in rows}

    async def type_names(self) -> dict[int, str]:
        rows = (await self._session.execute(select(TipoAlerta))).scalars().all()
        return {r.tipo_alerta_id: r.nombre for r in rows}

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
            cond.append(TipoAlerta.nombre == tipo)
        if venture_ids is not None:
            cond.append(Alerta.emprendimiento_id.in_(venture_ids))
        join = Alerta.tipo_alerta_id == TipoAlerta.tipo_alerta_id
        total = (
            await self._session.execute(
                select(func.count())
                .select_from(Alerta)
                .join(TipoAlerta, join)
                .where(*cond)
            )
        ).scalar_one()
        stmt = (
            select(Alerta)
            .join(TipoAlerta, join)
            .where(*cond)
            .order_by(Alerta.fecha_generacion.desc(), Alerta.alerta_id.desc())
            .offset(offset)
            .limit(limit)
        )
        return list((await self._session.execute(stmt)).scalars().all()), total

    async def open_keys(self) -> set[tuple[int, str]]:
        """`(emprendimiento, tipo)` con alerta abierta (evita duplicados)."""
        stmt = (
            select(Alerta.emprendimiento_id, TipoAlerta.nombre)
            .join(TipoAlerta, Alerta.tipo_alerta_id == TipoAlerta.tipo_alerta_id)
            .where(Alerta.estado.in_(OPEN_STATES))
        )
        return {(r[0], r[1]) for r in (await self._session.execute(stmt)).all()}

    async def count_open(self) -> int:
        return (
            await self._session.execute(
                select(func.count())
                .select_from(Alerta)
                .where(Alerta.estado.in_(OPEN_STATES))
            )
        ).scalar_one()

    async def counts(
        self, ids: list[int], start: datetime | None, end: datetime | None
    ) -> list[tuple[str | None, str, int]]:
        """`(estado, tipo, total)` de las alertas generadas en el periodo."""
        if not ids:
            return []
        stmt = (
            select(Alerta.estado, TipoAlerta.nombre, func.count())
            .join(TipoAlerta, Alerta.tipo_alerta_id == TipoAlerta.tipo_alerta_id)
            .where(Alerta.emprendimiento_id.in_(ids))
        )
        if start is not None:
            stmt = stmt.where(Alerta.fecha_generacion >= start)
        if end is not None:
            stmt = stmt.where(Alerta.fecha_generacion < end)
        stmt = stmt.group_by(Alerta.estado, TipoAlerta.nombre)
        return [(r[0], r[1], r[2]) for r in (await self._session.execute(stmt)).all()]

    async def open_by_venture(self, ids: list[int]) -> dict[int, int]:
        if not ids:
            return {}
        stmt = (
            select(Alerta.emprendimiento_id, func.count())
            .where(Alerta.emprendimiento_id.in_(ids), Alerta.estado.in_(OPEN_STATES))
            .group_by(Alerta.emprendimiento_id)
        )
        return {r[0]: r[1] for r in (await self._session.execute(stmt)).all()}

    async def list_for_report(
        self,
        ids: list[int],
        start: datetime | None,
        end: datetime | None,
        limit: int = 5000,
    ) -> list[Alerta]:
        if not ids:
            return []
        stmt = select(Alerta).where(Alerta.emprendimiento_id.in_(ids))
        if start is not None:
            stmt = stmt.where(Alerta.fecha_generacion >= start)
        if end is not None:
            stmt = stmt.where(Alerta.fecha_generacion < end)
        stmt = stmt.order_by(Alerta.fecha_generacion.desc(), Alerta.alerta_id.desc())
        return list((await self._session.execute(stmt.limit(limit))).scalars().all())
