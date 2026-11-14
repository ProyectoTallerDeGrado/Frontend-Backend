"""Servicio del coach: base de conocimiento (RAG), conversaciones y sentimiento."""

from __future__ import annotations

import math
import re
import unicodedata
from collections import defaultdict
from datetime import UTC, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.config import get_settings
from emprendeu.core.errors import Forbidden, PayloadTooLarge
from emprendeu.core.pagination import Page, PageParams
from emprendeu.modules.ai_assistant import schemas as s
from emprendeu.modules.ai_assistant.chunking import chunk_text
from emprendeu.modules.ai_assistant.exceptions import (
    AIUnavailable,
    ConversationNotFound,
    EmptyKnowledge,
    KnowledgeNotFound,
    NotEntrepreneur,
)
from emprendeu.modules.ai_assistant.extraction import extract_text
from emprendeu.modules.ai_assistant.llm import LLMClient
from emprendeu.modules.ai_assistant.models import (
    EMBEDDING_DIM,
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
    "No encontré información suficiente en la base documental del CIE-U "
    "para responder con certeza."
)
# Estados de un documento de conocimiento (columna `estado`, sin CHECK en la base).
PROCESSING, ACTIVE, FAILED, INACTIVE = "procesando", "activo", "error", "inactivo"
HISTORY_TURNS = 6  # mensajes previos que se envian al modelo
HANDOFF_KEYWORDS = ("financ", "credito", "inversi", "legal", "contrato", "demanda")
SYSTEM_PROMPT = (
    "Eres el coach virtual del CIE-U (Centro de Innovacion y Emprendimiento "
    "Universitario). Responde en espanol, claro y breve (maximo 6 oraciones), "
    "usando SOLO el contexto entregado. Si el contexto no alcanza, dilo. "
    "No des asesoria legal ni financiera definitiva.\n\nContexto:\n{context}"
)


# Brechas de la base: ventana por defecto, topes y similitud para unir preguntas.
GAPS_DEFAULT_DAYS = 90
GAPS_MAX_QUESTIONS = 500
GAPS_MAX_TOPICS = 50
GAPS_SIMILARITY = 0.8


def now() -> datetime:
    return datetime.now(UTC)


def _cosine(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b, strict=True))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    return dot / (na * nb) if na and nb else 0.0


def _group_by_similarity(
    vectors: list[list[float]], threshold: float
) -> list[list[int]]:
    """Agrupación voraz: cada vector se une al primer grupo cuyo representante
    se le parezca al menos `threshold`; si ninguno, abre uno nuevo."""
    groups: list[list[int]] = []
    for i, vector in enumerate(vectors):
        for group in groups:
            if _cosine(vectors[group[0]], vector) >= threshold:
                group.append(i)
                break
        else:
            groups.append([i])
    return groups


def _normalized(text: str) -> str:
    plain = unicodedata.normalize("NFKD", text.lower())
    plain = "".join(c for c in plain if not unicodedata.combining(c))
    return " ".join(re.sub(r"[^\w\s]", " ", plain).split())


def _group_by_text(texts: list[str]) -> list[list[int]]:
    """Sin modelo de embeddings: une solo las preguntas iguales (sin tildes ni signos)."""
    groups: dict[str, list[int]] = {}
    for i, text in enumerate(texts):
        groups.setdefault(_normalized(text), []).append(i)
    return list(groups.values())


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

    async def sentiment_points(
        self, since: datetime
    ) -> list[tuple[int, datetime, float]]:
        """`(emprendedor_id, fecha, indice)` desde `since`. Solo el índice anónimo
        (RF07): ni texto ni mensaje. Para indicadores agregados como la salud."""
        return await self._repo.sentiment_since(since)

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
        return await self._process(
            actor, body.titulo, body.descripcion, body.fuente, body.contenido
        )

    async def ingest_file(
        self,
        actor: CurrentUser,
        filename: str,
        data: bytes,
        titulo: str,
        descripcion: str | None,
        fuente: str | None,
    ) -> s.KnowledgeOut:
        """CU31: sube un archivo, lo trocea, calcula los embeddings y los guarda."""
        limit = get_settings().max_upload_mb * 1024 * 1024
        if len(data) > limit:
            raise PayloadTooLarge(
                "El archivo supera el tamano maximo permitido.",
                details={"max_mb": get_settings().max_upload_mb},
            )
        text = extract_text(filename, data)
        return await self._process(
            actor, titulo, descripcion, fuente or filename[:300], text
        )

    async def _process(
        self,
        actor: CurrentUser,
        titulo: str,
        descripcion: str | None,
        fuente: str | None,
        text: str,
    ) -> s.KnowledgeOut:
        """Estados: `procesando` -> `activo`, o `error` si el modelo no responde.

        El documento se guarda como `procesando` antes de calcular los embeddings
        para que la lista de la web lo muestre; si falla queda en `error` (sin
        fragmentos) y la peticion responde 503. Solo un documento `activo` se
        usa en las respuestas del coach.
        """
        chunks = chunk_text(text)
        if not chunks:
            raise EmptyKnowledge
        doc = DocumentoConocimiento(
            titulo=titulo,
            descripcion=descripcion,
            fuente=fuente,
            estado=PROCESSING,
            fecha_carga=now(),
        )
        await self._repo.add(doc)
        await self._repo.commit()
        try:
            vectors = self._checked(await self._llm.embed(chunks))
        except AIUnavailable:
            doc.estado = FAILED
            await self._audit.record(
                actor.usuario_id,
                "negocio.conocimiento",
                doc.titulo,
                tabla="documentos_conocimiento",
                id_registro=doc.documento_conocimiento_id,
                despues={"accion": "cargar", "resultado": "error"},
            )
            await self._repo.commit()
            raise
        await self._repo.add_all(
            [
                FragmentoDocumento(
                    documento_conocimiento_id=doc.documento_conocimiento_id,
                    numero_fragmento=i,
                    contenido=chunk,
                    embedding=vec,
                )
                for i, (chunk, vec) in enumerate(zip(chunks, vectors, strict=True))
            ]
        )
        doc.estado = ACTIVE
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
        doc.estado = INACTIVE
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

    # --- indice descargable (coach local del movil) ---------------------------

    async def knowledge_index(self) -> s.KnowledgeIndex:
        return s.KnowledgeIndex(
            modelo_embeddings=get_settings().ollama_embed_model,
            dimension=EMBEDDING_DIM,
            documentos=[
                s.IndexDocument(
                    documento_conocimiento_id=d.documento_conocimiento_id,
                    titulo=d.titulo,
                    fuente=d.fuente,
                    fecha_carga=d.fecha_carga,
                    total_fragmentos=n,
                )
                for d, n in await self._repo.active_documents()
            ],
        )

    async def knowledge_fragments(
        self, doc_id: int, params: PageParams, with_embedding: bool = True
    ) -> Page[s.FragmentOut]:
        """Fragmentos (con su vector si `with_embedding`); solo de documentos
        `activo` (si no, 404)."""
        doc = await self._repo.get_document(doc_id)
        if doc is None or doc.estado != ACTIVE:
            raise KnowledgeNotFound
        rows, total = await self._repo.fragments_page(
            doc_id, params.offset, params.page_size
        )
        return Page[s.FragmentOut].build(
            [
                s.FragmentOut(
                    numero_fragmento=f.numero_fragmento,
                    contenido=f.contenido,
                    # pgvector devuelve un ndarray: se pasa a floats de Python
                    embedding=[float(x) for x in f.embedding]
                    if with_embedding
                    else None,
                )
                for f in rows
            ],
            params,
            total,
        )

    # --- brechas de la base (preguntas sin respuesta) --------------------------

    async def knowledge_gaps(
        self, desde: datetime | None = None, hasta: datetime | None = None
    ) -> s.KnowledgeGaps:
        """Preguntas que el coach no pudo responder, agrupadas por tema.

        Sirve para saber qué documentos faltan. **Anónimo:** solo el texto de la
        pregunta y su fecha, sin emprendedor ni conversación. Si el modelo de
        embeddings responde, agrupa por similitud; si no, por texto igual.
        """
        until = hasta or now()
        since = desde or until - timedelta(days=GAPS_DEFAULT_DAYS)
        questions = await self._repo.unanswered_questions(
            since, until, GAPS_MAX_QUESTIONS
        )
        if not questions:
            return s.KnowledgeGaps(
                desde=since, hasta=until, por_similitud=False, temas=[]
            )
        try:
            vectors = self._checked(await self._llm.embed([q for q, _ in questions]))
            groups = _group_by_similarity(vectors, GAPS_SIMILARITY)
            by_similarity = True
        except AIUnavailable:
            groups = _group_by_text([q for q, _ in questions])
            by_similarity = False
        topics: list[s.KnowledgeGap] = []
        for members in groups:
            # Lo más reciente primero: la pregunta representativa es la última.
            items = sorted(
                (questions[i] for i in members), key=lambda q: q[1], reverse=True
            )
            texts = list(dict.fromkeys(text for text, _ in items))
            topics.append(
                s.KnowledgeGap(
                    tema=texts[0],
                    veces=len(items),
                    ultima_fecha=items[0][1],
                    ejemplos=texts[1:4],
                )
            )
        topics.sort(key=lambda t: (t.veces, t.ultima_fecha), reverse=True)
        return s.KnowledgeGaps(
            desde=since,
            hasta=until,
            por_similitud=by_similarity,
            temas=topics[:GAPS_MAX_TOPICS],
        )

    async def status(self) -> s.AIStatus:
        return s.AIStatus(
            ollama_disponible=await self._llm.ping(),
            documentos_activos=await self._repo.count_active_documents(),
        )

    # --- chat -------------------------------------------------------------------

    @staticmethod
    def _checked(vectors: list[list[float]]) -> list[list[float]]:
        """El modelo de embeddings debe devolver `EMBEDDING_DIM` dimensiones."""
        for vector in vectors:
            if len(vector) != EMBEDDING_DIM:
                raise AIUnavailable(
                    f"El modelo de embeddings devuelve {len(vector)} dimensiones y "
                    f"la base espera {EMBEDDING_DIM}."
                )
        return vectors

    async def _retrieve(self, question: str) -> list[tuple[str, int, str]]:
        """Fragmentos relevantes: `(texto, documento_id, titulo)`."""
        settings = get_settings()
        if await self._repo.count_active_documents() == 0:
            return []
        (query,) = self._checked(await self._llm.embed([question]))
        nearest = await self._repo.nearest_fragments(query, settings.ai_top_k)
        return [
            (text, doc_id, title)
            for text, doc_id, title, sim in nearest
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
            venture_id = body.emprendimiento_id or ref.primary_venture_id
            if venture_id is not None and venture_id not in ref.emprendimiento_ids:
                raise Forbidden("No tienes acceso a este emprendimiento.")
            conversation = ConversacionIa(
                emprendedor_id=ref.emprendedor_id,
                emprendimiento_id=venture_id,
                fecha_inicio=now(),
            )
            await self._repo.add(conversation)
        else:
            found = await self._repo.get_conversation(body.conversacion_id)
            if found is None or found.emprendedor_id != ref.emprendedor_id:
                raise ConversationNotFound
            conversation = found
        # Turnos previos de la misma conversacion, para que el modelo no responda "en frio".
        history = [
            ("user" if m.tipo == "usuario" else "assistant", m.contenido)
            for m in (await self._repo.messages(conversation.conversacion_ia_id))[
                -HISTORY_TURNS:
            ]
        ]
        question = MensajeIa(
            conversacion_ia_id=conversation.conversacion_ia_id,
            tipo="usuario",
            contenido=body.mensaje,
            fecha=now(),
        )
        await self._repo.add(question)
        # RF07: el analisis de sentimiento se guarda anonimizado. Solo el indice
        # numerico, la fecha y el emprendedor; sin texto y sin enlace al mensaje.
        await self._repo.add(
            AnalisisSentimiento(
                emprendedor_id=ref.emprendedor_id,
                mensaje_ia_id=None,
                indice=score(body.mensaje),
                fecha=now(),
            )
        )
        try:
            sources = await self._retrieve(body.mensaje)
            if sources:
                context = "\n\n".join(f"[{title}] {text}" for text, _, title in sources)
                answer = await self._llm.chat(
                    SYSTEM_PROMPT.format(context=context), body.mensaje, history
                )
                # un documento por entrada, en orden de relevancia
                cited = list(
                    dict.fromkeys((doc_id, title) for _, doc_id, title in sources)
                )
            else:
                answer, cited = FALLBACK, []
            titles = [title for _, title in cited]
        except AIUnavailable:
            # Nada a medias: ni la conversacion nueva, ni la pregunta, ni el sentimiento.
            await self._repo.rollback()
            raise
        reply = MensajeIa(
            conversacion_ia_id=conversation.conversacion_ia_id,
            tipo="asistente",
            contenido=answer,
            fecha=now(),
            con_fuente=bool(titles),
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
            fuentes_detalle=[
                s.SourceOut(documento_conocimiento_id=doc_id, titulo=title)
                for doc_id, title in cited
            ],
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
