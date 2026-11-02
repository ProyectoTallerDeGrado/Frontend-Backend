"""Acceso a datos de ai_assistant."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.ai_assistant.models import (
    AnalisisSentimiento,
    ConversacionIa,
    DocumentoConocimiento,
    FragmentoDocumento,
    MensajeIa,
)


class AssistantRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def add(self, obj: object) -> None:
        self._session.add(obj)
        await self._session.flush()

    async def add_all(self, objs: list[object]) -> None:
        self._session.add_all(objs)
        await self._session.flush()

    # --- conocimiento ----------------------------------------------------------

    async def get_document(self, doc_id: int) -> DocumentoConocimiento | None:
        return await self._session.get(DocumentoConocimiento, doc_id)

    async def list_documents(self) -> list[tuple[DocumentoConocimiento, int]]:
        stmt = (
            select(
                DocumentoConocimiento,
                func.count(FragmentoDocumento.fragmento_documento_id),
            )
            .outerjoin(
                FragmentoDocumento,
                FragmentoDocumento.documento_conocimiento_id
                == DocumentoConocimiento.documento_conocimiento_id,
            )
            .group_by(DocumentoConocimiento.documento_conocimiento_id)
            .order_by(DocumentoConocimiento.documento_conocimiento_id.desc())
        )
        return [(r[0], int(r[1])) for r in (await self._session.execute(stmt)).all()]

    async def nearest_fragments(
        self, vector: list[float], limit: int
    ) -> list[tuple[str, str, float]]:
        """Fragmentos de documentos activos mas cercanos: `(texto, titulo, similitud)`.

        La similitud coseno es `1 - distancia`; el indice HNSW acelera el orden.
        """
        distance = FragmentoDocumento.embedding.cosine_distance(vector)
        stmt = (
            select(FragmentoDocumento.contenido, DocumentoConocimiento.titulo, distance)
            .join(
                DocumentoConocimiento,
                DocumentoConocimiento.documento_conocimiento_id
                == FragmentoDocumento.documento_conocimiento_id,
            )
            .where(DocumentoConocimiento.estado == "activo")
            .order_by(distance)
            .limit(limit)
        )
        return [
            (r[0], r[1], 1.0 - float(r[2]))
            for r in (await self._session.execute(stmt)).all()
        ]

    async def count_active_documents(self) -> int:
        return (
            await self._session.execute(
                select(func.count())
                .select_from(DocumentoConocimiento)
                .where(DocumentoConocimiento.estado == "activo")
            )
        ).scalar_one()

    # --- conversaciones --------------------------------------------------------

    async def get_conversation(self, conv_id: int) -> ConversacionIa | None:
        return await self._session.get(ConversacionIa, conv_id)

    async def conversations_of(
        self, emprendedor_id: int
    ) -> list[tuple[ConversacionIa, int]]:
        stmt = (
            select(ConversacionIa, func.count(MensajeIa.mensaje_ia_id))
            .outerjoin(
                MensajeIa,
                MensajeIa.conversacion_ia_id == ConversacionIa.conversacion_ia_id,
            )
            .where(ConversacionIa.emprendedor_id == emprendedor_id)
            .group_by(ConversacionIa.conversacion_ia_id)
            .order_by(ConversacionIa.conversacion_ia_id.desc())
        )
        return [(r[0], int(r[1])) for r in (await self._session.execute(stmt)).all()]

    async def messages(self, conv_id: int) -> list[MensajeIa]:
        stmt = (
            select(MensajeIa)
            .where(MensajeIa.conversacion_ia_id == conv_id)
            .order_by(MensajeIa.mensaje_ia_id)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    # --- sentimiento -----------------------------------------------------------

    async def sentiment_since(
        self, since: datetime, emprendedor_id: int | None = None
    ) -> list[tuple[int, datetime, float]]:
        stmt = select(
            AnalisisSentimiento.emprendedor_id,
            AnalisisSentimiento.fecha,
            AnalisisSentimiento.indice,
        ).where(
            AnalisisSentimiento.fecha >= since, AnalisisSentimiento.indice.is_not(None)
        )
        if emprendedor_id is not None:
            stmt = stmt.where(AnalisisSentimiento.emprendedor_id == emprendedor_id)
        return [
            (r[0], r[1], float(r[2])) for r in (await self._session.execute(stmt)).all()
        ]
