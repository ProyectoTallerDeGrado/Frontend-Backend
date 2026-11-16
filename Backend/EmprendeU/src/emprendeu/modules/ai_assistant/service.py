"""Servicio del coach: base de conocimiento (RAG), conversaciones y sentimiento."""

from __future__ import annotations

import math
import re
import unicodedata
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from typing import Protocol

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.config import get_settings
from emprendeu.core.errors import Forbidden, NotFoundError, PayloadTooLarge
from emprendeu.core.mailer import Mailer
from emprendeu.core.pagination import Page, PageParams
from emprendeu.core.periods import period_bounds
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
from emprendeu.modules.ai_assistant.sentiment import (
    CLASSIFY_PROMPT,
    EMOTIONS,
    TOPICS,
    analyze_lexical,
    parse_model_reply,
)
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.mentoring import MentoringService
from emprendeu.modules.users import CurrentUser, build_user_service
from emprendeu.modules.ventures import VentureService

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


# Se antepone a la respuesta cuando el mensaje muestra senales de riesgo.
SUPPORT_NOTE = (
    "Suena a que estás pasando por un momento difícil, y es válido sentirse así. "
    "Te recomiendo hablarlo con tu asesor del CIE-U: no tienes que cargar con esto "
    "a solas."
)

# Bienestar: periodo por defecto, minimo de mensajes para dar un nivel y umbrales.
WELLBEING_DEFAULT_DAYS = 28
WELLBEING_MIN_MESSAGES = 3
WELLBEING_RED = -0.3  # promedio igual o menor: rojo
WELLBEING_AMBER = 0.0  # promedio igual o menor: ambar
WELLBEING_DROP = 0.25  # caida frente al periodo anterior: ambar
WELLBEING_TREND = 0.1  # cambio minimo para decir que sube o baja
WELLBEING_WEEKS = 12  # semanas de la serie del detalle
REPORT_ROLES = ("coordinador", "administrador")
_LEVEL_ORDER = {"rojo": 0, "ambar": 1, "verde": 2, "sin_datos": 3}


class RiskNotifier(Protocol):
    """Avisa al personal de una senal de riesgo (lo implementa `risk_alerts.py`)."""

    async def notify(self, emprendedor_id: int) -> None: ...


@dataclass(frozen=True, slots=True)
class PendingAnalysis:
    """Lo que la tarea en segundo plano necesita para afinar un analisis.

    El texto solo vive en memoria durante la peticion: no se guarda.
    """

    analysis_id: int
    emprendedor_id: int
    mensaje: str
    riesgo: bool


@dataclass(frozen=True, slots=True)
class ChatOutcome:
    reply: s.ChatReply
    pending: PendingAnalysis


class WellbeingNotFound(NotFoundError):
    code = "wellbeing_not_found"

    def __init__(self) -> None:
        super().__init__("Emprendedor no encontrado.")


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
    def __init__(
        self,
        session: AsyncSession,
        llm: LLMClient | None = None,
        notifier: RiskNotifier | None = None,
    ) -> None:
        self._session = session
        self._repo = AssistantRepository(session)
        self._llm_or_none = llm
        self._notifier = notifier
        self._audit = AuditService(session)
        self._entrepreneurs = EntrepreneurService(session)
        self._mentoring = MentoringService(session)
        self._ventures = VentureService(session)

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
        return (await self.chat_detailed(user, body)).reply

    async def chat_detailed(
        self, user: CurrentUser, body: s.ChatRequest
    ) -> ChatOutcome:
        """Responde y deja listo lo que hace falta para afinar el analisis de animo."""
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
        # RF07: del analisis se guarda el indice, la emocion, el tema y si hay riesgo,
        # con la fecha y el emprendedor; nunca el texto ni el enlace al mensaje.
        # Aqui va el analisis por palabras (inmediato); el modelo lo afina despues.
        first = analyze_lexical(body.mensaje)
        analysis = AnalisisSentimiento(
            emprendedor_id=ref.emprendedor_id,
            mensaje_ia_id=None,
            indice=first.indice,
            fecha=now(),
            emocion=first.emocion,
            tema=first.tema,
            riesgo=first.riesgo,
            origen="servidor",
            metodo=first.metodo,
        )
        await self._repo.add(analysis)
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
        if first.riesgo:
            answer = f"{SUPPORT_NOTE}\n\n{answer}"
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
        reply_out = s.ChatReply(
            conversacion_id=conversation.conversacion_ia_id,
            pregunta=self._message_out(question),
            respuesta=self._message_out(reply),
            fuente=bool(titles),
            fuentes=titles,
            fuentes_detalle=[
                s.SourceOut(documento_conocimiento_id=doc_id, titulo=title)
                for doc_id, title in cited
            ],
            derivar_mentor=first.riesgo
            or not titles
            or any(k in lowered for k in HANDOFF_KEYWORDS),
        )
        return ChatOutcome(
            reply_out,
            PendingAnalysis(
                analysis.analisis_sentimiento_id,
                ref.emprendedor_id,
                body.mensaje,
                first.riesgo,
            ),
        )

    # --- animo: afinado con el modelo y coach local ----------------------------

    async def refine_sentiment(self, pending: PendingAnalysis) -> None:
        """Despues de responder: el modelo afina el analisis y, si hay riesgo, se avisa.

        Si el modelo no responde o devuelve algo fuera de las listas, queda el analisis
        por palabras. Nunca falla hacia afuera: es una tarea en segundo plano.
        """
        riesgo = pending.riesgo
        if get_settings().ai_sentiment_model and self._llm_or_none is not None:
            try:
                raw = await self._llm_or_none.chat(CLASSIFY_PROMPT, pending.mensaje)
            except AIUnavailable:
                raw = ""
            refined = parse_model_reply(raw, pending.mensaje)
            row = await self._repo.get_analysis(pending.analysis_id)
            if refined is not None and row is not None:
                row.indice = refined.indice  # type: ignore[assignment]  # Numeric acepta float
                row.emocion = refined.emocion
                row.tema = refined.tema
                row.riesgo = refined.riesgo
                row.metodo = refined.metodo
                riesgo = refined.riesgo
                await self._repo.commit()
        if riesgo and self._notifier is not None:
            await self._notifier.notify(pending.emprendedor_id)

    async def sync_sentiment(
        self, user: CurrentUser, body: s.SentimentSync
    ) -> s.SentimentSyncResult:
        """Resultados del coach local (sin internet). Llega la clasificacion, no el texto.

        Idempotente por `referencia_cliente`: reenviar un lote no duplica nada.
        """
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if ref is None:
            raise NotEntrepreneur
        unique = {item.referencia_cliente: item for item in body.items}
        known = await self._repo.existing_references(ref.emprendedor_id, list(unique))
        moment = now()
        fresh = [item for key, item in unique.items() if key not in known]
        await self._repo.add_all(
            [
                AnalisisSentimiento(
                    emprendedor_id=ref.emprendedor_id,
                    mensaje_ia_id=None,
                    indice=round(item.indice, 5),
                    # El reloj del celular puede estar adelantado.
                    fecha=min(item.fecha.astimezone(UTC), moment),
                    emocion=item.emocion,
                    tema=item.tema,
                    riesgo=item.riesgo,
                    origen="local",
                    metodo="lexico",
                    referencia_cliente=item.referencia_cliente,
                )
                for item in fresh
            ]
        )
        await self._repo.commit()
        if self._notifier is not None and any(item.riesgo for item in fresh):
            await self._notifier.notify(ref.emprendedor_id)
        return s.SentimentSyncResult(
            registrados=len(fresh), duplicados=len(body.items) - len(fresh)
        )

    # --- bienestar (solo personal) ---------------------------------------------

    async def _scope(self, actor: CurrentUser) -> list[int] | None:
        """Emprendedores que el actor puede ver; `None` = todos.

        Un asesor solo ve a los integrantes de sus emprendimientos asignados.
        """
        if actor.rol != "asesor":
            return None
        ids: dict[int, None] = {}
        for a in await self._mentoring.list_assignments(actor.usuario_id, None):
            if a.estado != "activa":
                continue
            for eid in await self._entrepreneurs.entrepreneur_ids_of_venture(
                a.emprendimiento_id
            ):
                ids[eid] = None
        return list(ids)

    @staticmethod
    def _period(desde: date | None, hasta: date | None) -> tuple[date, date]:
        end = hasta or now().date()
        start = desde or end - timedelta(days=WELLBEING_DEFAULT_DAYS - 1)
        return (start, end) if start <= end else (end, start)

    @staticmethod
    def _top(values: list[str | None], order: tuple[str, ...]) -> str | None:
        """La clave mas frecuente; en empate, la primera segun `order`."""
        counts = Counter(v for v in values if v)
        if not counts:
            return None
        best = max(counts.values())
        return next(k for k in order if counts.get(k) == best)

    def _summarize(
        self,
        emprendedor_id: int,
        current: list[AnalisisSentimiento],
        previous: list[AnalisisSentimiento],
        names: dict[int, str],
        ventures: list[str],
    ) -> s.WellbeingRow:
        avg = (
            round(sum(float(r.indice or 0) for r in current) / len(current), 4)
            if current
            else None
        )
        before = (
            round(sum(float(r.indice or 0) for r in previous) / len(previous), 4)
            if len(previous) >= WELLBEING_MIN_MESSAGES
            else None
        )
        risks = sum(1 for r in current if r.riesgo)
        delta = avg - before if avg is not None and before is not None else None
        if risks:
            nivel = "rojo"
        elif avg is None or len(current) < WELLBEING_MIN_MESSAGES:
            nivel = "sin_datos"
        elif avg <= WELLBEING_RED:
            nivel = "rojo"
        elif avg <= WELLBEING_AMBER or (delta is not None and delta <= -WELLBEING_DROP):
            nivel = "ambar"
        else:
            nivel = "verde"
        tendencia = None
        if delta is not None:
            tendencia = (
                "sube"
                if delta >= WELLBEING_TREND
                else "baja"
                if delta <= -WELLBEING_TREND
                else "estable"
            )
        # Lo que conviene atender va primero: una emocion dificil gana el empate.
        emotion_order = (
            "desanimo",
            "frustracion",
            "estres",
            "preocupacion",
            "motivacion",
            "tranquilidad",
            "neutral",
        )
        return s.WellbeingRow(
            emprendedor_id=emprendedor_id,
            nombre=names.get(emprendedor_id, "Emprendedor"),
            emprendimientos=ventures,
            nivel=nivel,  # type: ignore[arg-type]  # una de las cuatro claves
            indice_promedio=avg,
            indice_anterior=before,
            tendencia=tendencia,  # type: ignore[arg-type]
            emocion_principal=self._top([r.emocion for r in current], emotion_order),  # type: ignore[arg-type]
            tema_principal=self._top([r.tema for r in current], TOPICS),  # type: ignore[arg-type]
            mensajes=len(current),
            senales_riesgo=risks,
            ultima_fecha=max((r.fecha for r in current if r.fecha), default=None),
        )

    async def _rows(
        self, start: date, end: date, scope: list[int] | None
    ) -> tuple[list[s.WellbeingRow], dict[int, list[AnalisisSentimiento]]]:
        since, until = period_bounds(start, end)
        assert since is not None and until is not None
        span = until - since
        current: dict[int, list[AnalisisSentimiento]] = defaultdict(list)
        previous: dict[int, list[AnalisisSentimiento]] = defaultdict(list)
        for row in await self._repo.analyses_between(since - span, until, scope):
            bucket = (
                current if row.fecha is not None and row.fecha >= since else previous
            )
            bucket[row.emprendedor_id].append(row)
        ids = list(current)
        names = await self._entrepreneurs.names_by_entrepreneur(ids)
        venture_ids = {
            eid: await self._entrepreneurs.venture_ids_of_entrepreneur(eid)
            for eid in ids
        }
        venture_names = await self._ventures.names_by_ids(
            sorted({v for vs in venture_ids.values() for v in vs})
        )
        rows = [
            self._summarize(
                eid,
                current[eid],
                previous.get(eid, []),
                names,
                [venture_names[v] for v in venture_ids[eid] if v in venture_names],
            )
            for eid in ids
        ]
        rows.sort(
            key=lambda r: (
                _LEVEL_ORDER[r.nivel],
                r.indice_promedio if r.indice_promedio is not None else 0.0,
                r.nombre,
            )
        )
        return rows, current

    async def wellbeing(
        self, actor: CurrentUser, desde: date | None, hasta: date | None
    ) -> s.WellbeingReport:
        """Animo por emprendedor en el periodo, del mas preocupante al que mejor va."""
        start, end = self._period(desde, hasta)
        rows, _ = await self._rows(start, end, await self._scope(actor))
        return s.WellbeingReport(
            desde=start,
            hasta=end,
            minimo_mensajes=WELLBEING_MIN_MESSAGES,
            emprendedores=rows,
        )

    async def wellbeing_detail(
        self,
        actor: CurrentUser,
        emprendedor_id: int,
        desde: date | None,
        hasta: date | None,
    ) -> s.WellbeingDetail:
        """Detalle de una persona. Cada consulta queda en auditoria."""
        if await self._entrepreneurs.ref_for_entrepreneur(emprendedor_id) is None:
            raise WellbeingNotFound
        scope = await self._scope(actor)
        if scope is not None and emprendedor_id not in scope:
            raise Forbidden("Solo puedes ver a los emprendedores que tienes asignados.")
        start, end = self._period(desde, hasta)
        rows, current = await self._rows(start, end, [emprendedor_id])
        names = await self._entrepreneurs.names_by_entrepreneur([emprendedor_id])
        summary = (
            rows[0] if rows else self._summarize(emprendedor_id, [], [], names, [])
        )
        mine = current.get(emprendedor_id, [])
        weeks: dict[str, list[float]] = defaultdict(list)
        for _, when, idx in await self._repo.sentiment_since(
            now() - timedelta(weeks=WELLBEING_WEEKS), emprendedor_id
        ):
            weeks[_week_key(when)].append(idx)

        def counts(
            values: list[str | None], order: tuple[str, ...]
        ) -> list[s.CountOut]:
            found = Counter(v for v in values if v)
            return [
                s.CountOut(clave=k, total=found[k])
                for k in sorted(found, key=lambda k: (-found[k], order.index(k)))
            ]

        await self._audit.record(
            actor.usuario_id,
            "negocio.bienestar",
            summary.nombre,
            tabla="emprendedor",
            id_registro=emprendedor_id,
        )
        await self._repo.commit()
        return s.WellbeingDetail(
            desde=start,
            hasta=end,
            resumen=summary,
            semanas=[
                s.SentimentPoint(
                    semana=week,
                    indice_promedio=round(sum(v) / len(v), 4),
                    mensajes=len(v),
                )
                for week, v in sorted(weeks.items())
            ],
            emociones=counts([r.emocion for r in mine], EMOTIONS),
            temas=counts([r.tema for r in mine], TOPICS),
            por_origen=counts([r.origen for r in mine], ("servidor", "local")),
        )

    async def weekly_report(self, mailer: Mailer) -> int:
        """Informe semanal por correo a coordinacion y administracion.

        Solo totales: sin nombres, porque el correo no es un canal para datos de
        animo de una persona. Devuelve a cuantos destinatarios se envio.
        """
        end = now().date()
        start = end - timedelta(days=6)
        rows, _ = await self._rows(start, end, None)
        level = Counter(r.nivel for r in rows)
        risks = sum(r.senales_riesgo for r in rows)
        body = "\n".join(
            [
                f"Bienestar de los emprendedores, del {start:%d/%m/%Y} al {end:%d/%m/%Y}.",
                "",
                f"Necesitan atencion (rojo): {level['rojo']}",
                f"Para seguir de cerca (ambar): {level['ambar']}",
                f"Van bien (verde): {level['verde']}",
                f"Con pocos mensajes para evaluar: {level['sin_datos']}",
                f"Senales de riesgo en la semana: {risks}",
                "",
                f"Detalle por persona: {get_settings().web_url.rstrip('/')}/wellbeing",
                "",
                "Es una senal orientativa a partir de las conversaciones con el coach, "
                "no un diagnostico. No se guarda el texto de los mensajes.",
            ]
        )
        recipients = await build_user_service(self._session).emails_by_roles(
            REPORT_ROLES
        )
        for email in recipients:
            await mailer.send(email, "CIE-U · Informe semanal de bienestar", body)
        return len(recipients)

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
