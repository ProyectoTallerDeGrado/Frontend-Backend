"""Servicio del coach: base de conocimiento (RAG), conversaciones y sentimiento."""

from __future__ import annotations

from collections import defaultdict
from datetime import UTC, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.config import get_settings
from emprendeu.modules.ai_assistant import schemas as s
from emprendeu.modules.ai_assistant.chunking import chunk_text, cosine
from emprendeu.modules.ai_assistant.exceptions import (
    AIUnavailable,
    ConversationNotFound,
    EmptyKnowledge,
    KnowledgeNotFound,
    NotEntrepreneur,
)
from emprendeu.modules.ai_assistant.llm import LLMClient
from emprendeu.modules.ai_assistant.models import (
    AnalisisSentimiento,
    ConversacionIa,
    DocumentoConocimiento,
    FragmentoDocumento,
    MensajeIa,
)
from emprendeu.modules.ai_assistant.repository import AssistantRepository
from emprendeu.modules.ai_assistant.sentiment import score
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.users import CurrentUser

FALLBACK = (
    "No encontre informacion suficiente en la base documental del CIE-U "
    "para responder con certeza."
)
HANDOFF_KEYWORDS = ("financ", "credito", "inversi", "legal", "contrato", "demanda")
SYSTEM_PROMPT = (
    "Eres el coach virtual del CIE-U (Centro de Innovacion y Emprendimiento "
    "Universitario). Responde en espanol, claro y breve (maximo 6 oraciones), "
    "usando SOLO el contexto entregado. Si el contexto no alcanza, dilo. "
    "No des asesoria legal ni financiera definitiva.\n\nContexto:\n{context}"
)


def now() -> datetime:
    return datetime.now(UTC)


def _week_key(moment: datetime) -> str:
    year, week, _ = moment.isocalendar()
    return f"{year}-W{week:02d}"


class AssistantService:
    def __init__(self, session: AsyncSession, llm: LLMClient | None = None) -> None:
        self._repo = AssistantRepository(session)
        self._llm_or_none = llm
        self._audit = AuditService(session)
        self._entrepreneurs = EntrepreneurService(session)

    @property
    def _llm(self) -> LLMClient:
        if self._llm_or_none is None:
            raise AIUnavailable("Servicio de IA no configurado.")
        return self._llm_or_none

    # --- API publica para otros modulos --------------------------------------

    async def sentiment_drops(self, drop_pct: int, periods: int) -> list[int]:
        """Emprendedores con `periods` semanas seguidas de caida >= `drop_pct`.

        Se compara el indice promedio semanal (reescalado a 0-100) contra el de
        la semana anterior. Solo cuentan semanas con mensajes.
        """
        since = now() - timedelta(weeks=periods + 2)
        by_user: dict[int, dict[str, list[float]]] = defaultdict(
            lambda: defaultdict(list)
        )
        for eid, when, idx in await self._repo.sentiment_since(since):
            by_user[eid][_week_key(when)].append((idx + 1) * 50)
        flagged: list[int] = []
        for eid, weeks in by_user.items():
            ordered = [sum(v) / len(v) for _, v in sorted(weeks.items())]
            if len(ordered) < periods + 1:
                continue
            tail = ordered[-(periods + 1) :]
            drops = [
                (prev - cur) / prev * 100 if prev > 0 else 0.0
                for prev, cur in zip(tail, tail[1:], strict=False)
            ]
            if all(d >= drop_pct for d in drops):
                flagged.append(eid)
        return flagged

    # --- base de conocimiento ------------------------------------------------

    async def ingest(
        self, actor: CurrentUser, body: s.KnowledgeCreate
    ) -> s.KnowledgeOut:
        chunks = chunk_text(body.contenido)
        if not chunks:
            raise EmptyKnowledge
        vectors = await self._llm.embed(chunks)  # falla antes de tocar la base
        doc = DocumentoConocimiento(
            titulo=body.titulo,
            descripcion=body.descripcion,
            fuente=body.fuente,
            estado="activo",
            fecha_carga=now(),
        )
        await self._repo.add(doc)
        await self._repo.add_all(
            [
                FragmentoDocumento(
                    documento_conocimiento_id=doc.documento_conocimiento_id,
                    numero_fragmento=i,
                    contenido=text,
                    embedding={"vector": vec},
                )
                for i, (text, vec) in enumerate(zip(chunks, vectors, strict=True))
            ]
        )
        await self._audit.record(
            actor.usuario_id,
            "negocio.conocimiento",
            doc.titulo,
            tabla="documentos_conocimiento",
            id_registro=doc.documento_conocimiento_id,
            despues={"accion": "cargar", "fragmentos": len(chunks)},
        )
        await self._repo.commit()
        return self._knowledge_out(doc, len(chunks))

    @staticmethod
    def _knowledge_out(d: DocumentoConocimiento, fragments: int) -> s.KnowledgeOut:
        return s.KnowledgeOut(
            documento_conocimiento_id=d.documento_conocimiento_id,
            titulo=d.titulo,
            descripcion=d.descripcion,
            fuente=d.fuente,
            estado=d.estado,
            fecha_carga=d.fecha_carga,
            total_fragmentos=fragments,
        )

    async def list_knowledge(self) -> list[s.KnowledgeOut]:
        return [self._knowledge_out(d, n) for d, n in await self._repo.list_documents()]

    async def deactivate_knowledge(
        self, actor: CurrentUser, doc_id: int
    ) -> s.KnowledgeOut:
        doc = await self._repo.get_document(doc_id)
        if doc is None:
            raise KnowledgeNotFound
        doc.estado = "inactivo"
        await self._audit.record(
            actor.usuario_id,
            "negocio.conocimiento",
            doc.titulo,
            tabla="documentos_conocimiento",
            id_registro=doc_id,
            despues={"accion": "desactivar"},
        )
        await self._repo.commit()
        count = dict(
            (d.documento_conocimiento_id, n)
            for d, n in await self._repo.list_documents()
        )
        return self._knowledge_out(doc, count.get(doc_id, 0))

    async def status(self) -> s.AIStatus:
        return s.AIStatus(
            ollama_disponible=await self._llm.ping(),
            documentos_activos=await self._repo.count_active_documents(),
        )

    # --- chat -------------------------------------------------------------------

    async def _retrieve(self, question: str) -> list[tuple[str, str]]:
        settings = get_settings()
        fragments = await self._repo.active_fragments()
        if not fragments:
            return []
        (query,) = await self._llm.embed([question])
        scored = []
        for frag, title in fragments:
            vector = (frag.embedding or {}).get("vector")
            if isinstance(vector, list):
                scored.append((cosine(query, vector), frag.contenido, title))
        scored.sort(key=lambda t: t[0], reverse=True)
        return [
            (text, title)
            for sim, text, title in scored[: settings.ai_top_k]
            if sim >= settings.ai_min_similarity
        ]

    @staticmethod
    def _message_out(m: MensajeIa) -> s.MessageOut:
        return s.MessageOut(
            mensaje_id=m.mensaje_ia_id,
            tipo=m.tipo,
            contenido=m.contenido,
            fecha=m.fecha,
        )

    async def chat(self, user: CurrentUser, body: s.ChatRequest) -> s.ChatReply:
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if ref is None:
            raise NotEntrepreneur
        if body.conversacion_id is None:
            conversation = ConversacionIa(
                emprendedor_id=ref.emprendedor_id,
                emprendimiento_id=ref.primary_venture_id,
                fecha_inicio=now(),
            )
            await self._repo.add(conversation)
        else:
            found = await self._repo.get_conversation(body.conversacion_id)
            if found is None or found.emprendedor_id != ref.emprendedor_id:
                raise ConversationNotFound
            conversation = found
        question = MensajeIa(
            conversacion_ia_id=conversation.conversacion_ia_id,
            tipo="usuario",
            contenido=body.mensaje,
            fecha=now(),
        )
        await self._repo.add(question)
        await self._repo.add(
            AnalisisSentimiento(
                emprendedor_id=ref.emprendedor_id,
                mensaje_ia_id=question.mensaje_ia_id,
                indice=score(body.mensaje),
                fecha=now(),
            )
        )
        sources = await self._retrieve(body.mensaje)
        if sources:
            context = "\n\n".join(f"[{title}] {text}" for text, title in sources)
            answer = await self._llm.chat(
                SYSTEM_PROMPT.format(context=context), body.mensaje
            )
            titles = list(dict.fromkeys(title for _, title in sources))
        else:
            answer, titles = FALLBACK, []
        reply = MensajeIa(
            conversacion_ia_id=conversation.conversacion_ia_id,
            tipo="asistente",
            contenido=answer,
            fecha=now(),
        )
        await self._repo.add(reply)
        conversation.fecha_fin = now()
        await self._repo.commit()
        lowered = body.mensaje.lower()
        return s.ChatReply(
            conversacion_id=conversation.conversacion_ia_id,
            pregunta=self._message_out(question),
            respuesta=self._message_out(reply),
            fuente=bool(titles),
            fuentes=titles,
            derivar_mentor=not titles or any(k in lowered for k in HANDOFF_KEYWORDS),
        )

    async def my_conversations(self, user: CurrentUser) -> list[s.ConversationOut]:
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if ref is None:
            return []
        return [
            s.ConversationOut(
                conversacion_id=c.conversacion_ia_id,
                fecha_inicio=c.fecha_inicio,
                fecha_fin=c.fecha_fin,
                total_mensajes=n,
            )
            for c, n in await self._repo.conversations_of(ref.emprendedor_id)
        ]

    async def conversation_messages(
        self, user: CurrentUser, conv_id: int
    ) -> list[s.MessageOut]:
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        conversation = await self._repo.get_conversation(conv_id)
        if (
            conversation is None
            or ref is None
            or conversation.emprendedor_id != ref.emprendedor_id
        ):
            raise ConversationNotFound
        return [self._message_out(m) for m in await self._repo.messages(conv_id)]

    # --- sentimiento (solo personal autorizado) --------------------------------

    async def sentiment_series(
        self, emprendedor_id: int, weeks: int = 8
    ) -> list[s.SentimentPoint]:
        since = now() - timedelta(weeks=weeks)
        buckets: dict[str, list[float]] = defaultdict(list)
        for _, when, idx in await self._repo.sentiment_since(since, emprendedor_id):
            buckets[_week_key(when)].append(idx)
        return [
            s.SentimentPoint(
                semana=week,
                indice_promedio=round(sum(v) / len(v), 4),
                mensajes=len(v),
            )
            for week, v in sorted(buckets.items())
        ]
