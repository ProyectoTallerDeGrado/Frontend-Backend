"""Acceso a datos de documents."""

from __future__ import annotations

from sqlalchemy import column, select, table
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.documents.models import Documento

# Lectura ligera del hito sin importar el modelo del modulo ventures.
_hito = table("hito", column("hitoid"), column("emprendimientoid"), schema="cieu")


class DocumentRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def add(self, doc: Documento) -> None:
        self._session.add(doc)
        await self._session.flush()

    async def get(self, documento_id: int) -> Documento | None:
        return await self._session.get(Documento, documento_id)

    async def milestone_belongs(self, hito_id: int, venture_id: int) -> bool:
        stmt = select(_hito.c.hitoid).where(
            _hito.c.hitoid == hito_id, _hito.c.emprendimientoid == venture_id
        )
        return (await self._session.execute(stmt)).first() is not None

    async def delete(self, doc: Documento) -> None:
        await self._session.delete(doc)
        await self._session.flush()

    async def list(
        self,
        *,
        venture_ids: list[int] | None,
        venture_id: int | None,
        usuario_id: int | None,
        hito_id: int | None = None,
    ) -> list[Documento]:
        stmt = select(Documento).order_by(Documento.documento_id.desc())
        if venture_id is not None:
            stmt = stmt.where(Documento.emprendimiento_id == venture_id)
        if venture_ids is not None:
            stmt = stmt.where(Documento.emprendimiento_id.in_(venture_ids))
        if usuario_id is not None:
            stmt = stmt.where(Documento.usuario_id == usuario_id)
        if hito_id is not None:
            stmt = stmt.where(Documento.hito_id == hito_id)
        return list((await self._session.execute(stmt)).scalars().all())
