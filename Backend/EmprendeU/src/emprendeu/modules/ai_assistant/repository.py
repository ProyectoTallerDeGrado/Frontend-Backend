"""Acceso a datos de ai_assistant."""

from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.ai_assistant.models import (
    AnalisisSentimiento,
    AyudaUsoDiario,
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

    async def get_analysis(self, analysis_id: int) -> AnalisisSentimiento | None:
        return await self._session.get(AnalisisSentimiento, analysis_id)

    async def analyses_between(
        self,
        start: datetime,
        end: datetime,
        emprendedor_ids: list[int] | None = None,
    ) -> list[AnalisisSentimiento]:
        """Analisis con fecha en `[start, end)`; `emprendedor_ids` acota el alcance."""
        stmt = select(AnalisisSentimiento).where(
            AnalisisSentimiento.fecha >= start,
            AnalisisSentimiento.fecha < end,
            AnalisisSentimiento.indice.is_not(None),
        )
        if emprendedor_ids is not None:
            stmt = stmt.where(AnalisisSentimiento.emprendedor_id.in_(emprendedor_ids))
        return list((await self._session.execute(stmt)).scalars().all())

    async def existing_references(
        self, emprendedor_id: int, references: list[str]
    ) -> set[str]:
        stmt = select(AnalisisSentimiento.referencia_cliente).where(
            AnalisisSentimiento.emprendedor_id == emprendedor_id,
            AnalisisSentimiento.referencia_cliente.in_(references),
        )
        return {r for r in (await self._session.execute(stmt)).scalars().all() if r}


class HelpUsageRepository:
    """Contador diario de llamadas a Gemini del asistente de ayuda."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def calls_on(self, day: date) -> int:
        value = await self._session.scalar(
            select(AyudaUsoDiario.llamadas).where(AyudaUsoDiario.fecha == day)
        )
        return int(value or 0)

    async def reserve_call(self, day: date, limit: int) -> int | None:
        """Suma una llamada si no se paso el tope; devuelve el total o `None` si no hay cupo.

        Atomico (`INSERT ... ON CONFLICT DO UPDATE ... WHERE`): dos peticiones a la vez
        no pueden pasarse del limite.
        """
        stmt = (
            insert(AyudaUsoDiario)
            .values(fecha=day, llamadas=1)
            .on_conflict_do_update(
                index_elements=[AyudaUsoDiario.fecha],
                set_={"llamadas": AyudaUsoDiario.llamadas + 1},
                where=AyudaUsoDiario.llamadas < limit,
            )
            .returning(AyudaUsoDiario.llamadas)
        )
        if limit <= 0:
            return None
        value = await self._session.scalar(stmt)
        await self._session.commit()
        return None if value is None else int(value)

    async def release_call(self, day: date) -> None:
        """Devuelve el cupo de una llamada que fallo (Gemini no respondio)."""
        row = await self._session.get(AyudaUsoDiario, day)
        if row is not None and row.llamadas > 0:
            row.llamadas -= 1
            await self._session.commit()
