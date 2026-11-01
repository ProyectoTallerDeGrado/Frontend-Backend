"""Acceso a datos de documents."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.documents.models import Documento


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

    async def delete(self, doc: Documento) -> None:
        await self._session.delete(doc)
        await self._session.flush()

    async def list(
        self,
        *,
        venture_ids: list[int] | None,
        venture_id: int | None,
        usuario_id: int | None,
    ) -> list[Documento]:
        stmt = select(Documento).order_by(Documento.documento_id.desc())
        if venture_id is not None:
            stmt = stmt.where(Documento.emprendimiento_id == venture_id)
        if venture_ids is not None:
            stmt = stmt.where(Documento.emprendimiento_id.in_(venture_ids))
        if usuario_id is not None:
            stmt = stmt.where(Documento.usuario_id == usuario_id)
        return list((await self._session.execute(stmt)).scalars().all())
