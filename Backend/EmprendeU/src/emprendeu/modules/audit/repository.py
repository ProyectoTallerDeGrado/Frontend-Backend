"""Acceso a datos de la bitacora."""

from __future__ import annotations

from collections.abc import Sequence
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import column, func, select, table
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.audit.models import Bitacora

# Referencia ligera a `usuario` solo para mostrar el nombre del actor sin importar
# el modelo del modulo users (frontera entre modulos).
_usuario = table(
    "usuario", column("usuarioid"), column("nombre"), column("apellido"), schema="cieu"
)


class AuditRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def add(self, entry: Bitacora) -> None:
        self._session.add(entry)
        await self._session.flush()

    def _filters(self, categoria: str | None, resultado: str | None) -> list[Any]:
        conditions: list[Any] = []
        if categoria:
            conditions.append(Bitacora.accion.like(f"{categoria}.%"))
        if resultado:
            conditions.append(Bitacora.datos_nuevos["resultado"].astext == resultado)
        return conditions

    async def list(
        self,
        *,
        categoria: str | None,
        resultado: str | None,
        offset: int,
        limit: int,
    ) -> tuple[Sequence[tuple[Bitacora, str | None]], int]:
        conditions = self._filters(categoria, resultado)
        total = (
            await self._session.execute(
                select(func.count()).select_from(Bitacora).where(*conditions)
            )
        ).scalar_one()
        stmt = (
            select(Bitacora, _usuario.c.nombre + " " + _usuario.c.apellido)
            .outerjoin(_usuario, _usuario.c.usuarioid == Bitacora.usuario_id)
            .where(*conditions)
            .order_by(Bitacora.fecha.desc(), Bitacora.bitacora_id.desc())
            .offset(offset)
            .limit(limit)
        )
        rows = (await self._session.execute(stmt)).all()
        return [(r[0], r[1]) for r in rows], total

    async def login_dates(self, usuario_id: int, limit: int) -> list[datetime]:
        stmt = (
            select(Bitacora.fecha)
            .where(
                Bitacora.usuario_id == usuario_id, Bitacora.accion == "accesos.login"
            )
            .order_by(Bitacora.fecha.desc())
            .limit(limit)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def count(self) -> int:
        return (
            await self._session.execute(select(func.count()).select_from(Bitacora))
        ).scalar_one()

    @staticmethod
    def now() -> datetime:
        return datetime.now(UTC)
