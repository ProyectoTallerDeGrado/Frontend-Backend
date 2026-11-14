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

    async def rollback(self) -> None:
        await self._session.rollback()

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

    async def active_documents(self) -> list[tuple[DocumentoConocimiento, int]]:
        """Documentos `activo` con al menos un fragmento, del mas antiguo al mas nuevo."""
        total = func.count(FragmentoDocumento.fragmento_documento_id)
        stmt = (
            select(DocumentoConocimiento, total)
            .join(
                FragmentoDocumento,
                FragmentoDocumento.documento_conocimiento_id
                == DocumentoConocimiento.documento_conocimiento_id,
            )
            .where(DocumentoConocimiento.estado == "activo")
            .group_by(DocumentoConocimiento.documento_conocimiento_id)
            .order_by(DocumentoConocimiento.documento_conocimiento_id)
        )
        return [(r[0], int(r[1])) for r in (await self._session.execute(stmt)).all()]

    async def fragments_page(
        self, doc_id: int, offset: int, limit: int
    ) -> tuple[list[FragmentoDocumento], int]:
        where = FragmentoDocumento.documento_conocimiento_id == doc_id
        total = (
            await self._session.execute(
                select(func.count()).select_from(FragmentoDocumento).where(where)
            )
        ).scalar_one()
        stmt = (
            select(FragmentoDocumento)
            .where(where)
            .order_by(FragmentoDocumento.numero_fragmento)
            .offset(offset)
            .limit(limit)
        )
        return list((await self._session.execute(stmt)).scalars().all()), int(total)

    async def nearest_fragments(
        self, vector: list[float], limit: int
    ) -> list[tuple[str, int, str, float]]:
        """Fragmentos activos mas cercanos: `(texto, documento_id, titulo, similitud)`.

        La similitud coseno es `1 - distancia`; el indice HNSW acelera el orden.
        """
        distance = FragmentoDocumento.embedding.cosine_distance(vector)
        stmt = (
            select(
                FragmentoDocumento.contenido,
                DocumentoConocimiento.documento_conocimiento_id,
                DocumentoConocimiento.titulo,
                distance,
            )
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
            (r[0], int(r[1]), r[2], 1.0 - float(r[3]))
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

    async def unanswered_questions(
        self, since: datetime, until: datetime, limit: int
    ) -> list[tuple[str, datetime]]:
        """`(pregunta, fecha)` de las respuestas sin fuente en el periodo, las más
        recientes primero. La pregunta es el último mensaje del usuario anterior a
        la respuesta en la misma conversación. No devuelve quién preguntó."""
        replies = (
            await self._session.execute(
                select(
                    MensajeIa.conversacion_ia_id,
                    MensajeIa.mensaje_ia_id,
                    MensajeIa.fecha,
                )
                .where(
                    MensajeIa.tipo == "asistente",
                    MensajeIa.con_fuente.is_(False),
                    MensajeIa.fecha >= since,
                    MensajeIa.fecha <= until,
                )
                .order_by(MensajeIa.mensaje_ia_id.desc())
                .limit(limit)
            )
        ).all()
        if not replies:
            return []
        conv_ids = {r[0] for r in replies}
        asked = (
            await self._session.execute(
                select(
                    MensajeIa.conversacion_ia_id,
                    MensajeIa.mensaje_ia_id,
                    MensajeIa.contenido,
                )
                .where(
                    MensajeIa.conversacion_ia_id.in_(conv_ids),
                    MensajeIa.tipo == "usuario",
                )
                .order_by(MensajeIa.mensaje_ia_id)
            )
        ).all()
        by_conv: dict[int, list[tuple[int, str]]] = {}
        for conv_id, msg_id, text in asked:
            by_conv.setdefault(conv_id, []).append((msg_id, text))
        out: list[tuple[str, datetime]] = []
        for conv_id, reply_id, fecha in replies:
            before = [t for mid, t in by_conv.get(conv_id, []) if mid < reply_id]
            if before and fecha is not None:
                out.append((before[-1], fecha))
        return out

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
