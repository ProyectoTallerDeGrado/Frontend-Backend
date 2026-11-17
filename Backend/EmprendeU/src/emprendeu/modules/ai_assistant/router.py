"""HTTP del coach IA (prefijo /ai)."""

from datetime import date, datetime
from typing import Annotated

import structlog
from fastapi import APIRouter, BackgroundTasks, Depends, File, Form, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.config import get_settings
from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.db.session import SessionFactory, get_session, get_session_factory
from emprendeu.modules.ai_assistant import schemas as s
from emprendeu.modules.ai_assistant.gemini import HelpLLM, get_help_llm
from emprendeu.modules.ai_assistant.help_service import HelpService
from emprendeu.modules.ai_assistant.llm import LLMClient, get_llm
from emprendeu.modules.ai_assistant.risk_alerts import AlertRiskNotifier
from emprendeu.modules.ai_assistant.service import AssistantService, PendingAnalysis
from emprendeu.modules.users import (
    CurrentUser,
    CurrentUserDep,
    require_permission,
    require_staff_permission,
)

router = APIRouter(prefix="/ai", tags=["ai"])


def _svc(
    session: Annotated[AsyncSession, Depends(get_session)],
    llm: Annotated[LLMClient, Depends(get_llm)],
) -> AssistantService:
    return AssistantService(session, llm, AlertRiskNotifier(session))


async def _refine_sentiment(
    factory: SessionFactory, llm: LLMClient, pending: PendingAnalysis
) -> None:
    """Tarea en segundo plano tras responder: afina el animo con el modelo y avisa si
    hay riesgo. Usa su propia sesion y nunca propaga un error (la respuesta ya salio)."""
    try:
        async with factory() as session:
            service = AssistantService(session, llm, AlertRiskNotifier(session))
            await service.refine_sentiment(pending)
    except Exception:  # noqa: BLE001 - no hay a quien responderle
        structlog.get_logger("ai.sentiment").exception("refinado_fallido")


Svc = Annotated[AssistantService, Depends(_svc)]


def perm(name: str) -> object:
    return Depends(require_permission(name))


@router.post("/help", response_model=s.HelpReply)
async def help_assistant(
    body: s.HelpRequest,
    user: CurrentUserDep,
    session: Annotated[AsyncSession, Depends(get_session)],
    llm: Annotated[HelpLLM, Depends(get_help_llm)],
) -> s.HelpReply:
    """Ayuda de uso del panel (cualquier usuario autenticado). No guarda la conversacion."""
    return await HelpService(session, llm).answer(user, body)


@router.post("/chat", response_model=s.ChatReply)
async def chat(
    body: s.ChatRequest,
    service: Svc,
    user: Annotated[CurrentUser, perm("ia:registro")],
    background: BackgroundTasks,
    factory: Annotated[SessionFactory, Depends(get_session_factory)],
    llm: Annotated[LLMClient, Depends(get_llm)],
) -> s.ChatReply:
    outcome = await service.chat_detailed(user, body)
    background.add_task(_refine_sentiment, factory, llm, outcome.pending)
    return outcome.reply


@router.get("/conversations/me", response_model=list[s.ConversationOut])
async def my_conversations(
    service: Svc, user: Annotated[CurrentUser, perm("ia:consulta")]
) -> list[s.ConversationOut]:
    return await service.my_conversations(user)


@router.get("/conversations/{conv_id}/messages", response_model=list[s.MessageOut])
async def conversation_messages(
    conv_id: int, service: Svc, user: Annotated[CurrentUser, perm("ia:consulta")]
) -> list[s.MessageOut]:
    return await service.conversation_messages(user, conv_id)


@router.get("/knowledge", response_model=list[s.KnowledgeOut])
async def list_knowledge(
    service: Svc, _: Annotated[CurrentUser, perm("config:consulta")]
) -> list[s.KnowledgeOut]:
    return await service.list_knowledge()


@router.post(
    "/knowledge", response_model=s.KnowledgeOut, status_code=status.HTTP_201_CREATED
)
async def ingest_knowledge(
    body: s.KnowledgeCreate,
    service: Svc,
    actor: Annotated[CurrentUser, perm("config:modificacion")],
) -> s.KnowledgeOut:
    """Carga un texto pegado (coordinacion o administracion)."""
    return await service.ingest(actor, body)


@router.post(
    "/knowledge/upload",
    response_model=s.KnowledgeOut,
    status_code=status.HTTP_201_CREATED,
)
async def upload_knowledge(
    service: Svc,
    actor: Annotated[CurrentUser, perm("config:modificacion")],
    file: Annotated[UploadFile, File()],
    titulo: Annotated[str, Form(min_length=1, max_length=240)],
    descripcion: Annotated[str | None, Form()] = None,
    fuente: Annotated[str | None, Form(max_length=300)] = None,
) -> s.KnowledgeOut:
    """CU31: sube un archivo (txt, md, pdf o docx) y lo indexa."""
    limit = get_settings().max_upload_mb * 1024 * 1024
    data = await file.read(limit + 1)  # acota la memoria; el servicio rechaza el exceso
    return await service.ingest_file(
        actor, file.filename or "documento", data, titulo.strip(), descripcion, fuente
    )


@router.get("/knowledge/gaps", response_model=s.KnowledgeGaps)
async def knowledge_gaps(
    service: Svc,
    _: Annotated[CurrentUser, perm("config:consulta")],
    desde: datetime | None = None,
    hasta: datetime | None = None,
) -> s.KnowledgeGaps:
    """Preguntas sin respuesta del coach, agrupadas: qué documentos faltan."""
    return await service.knowledge_gaps(desde, hasta)


@router.get("/knowledge/index", response_model=s.KnowledgeIndex)
async def knowledge_index(
    service: Svc, _: Annotated[CurrentUser, perm("ia:consulta")]
) -> s.KnowledgeIndex:
    """Manifiesto de la base activa para el coach local del movil."""
    return await service.knowledge_index()


@router.get("/knowledge/{doc_id}/fragments", response_model=Page[s.FragmentOut])
async def knowledge_fragments(
    doc_id: int,
    service: Svc,
    params: PageParamsDep,
    _: Annotated[CurrentUser, perm("ia:consulta")],
    incluir_embedding: bool = True,
) -> Page[s.FragmentOut]:
    """Fragmentos de un documento activo; con `incluir_embedding=false` solo el texto
    (el movil recalcula los vectores con su propio modelo)."""
    return await service.knowledge_fragments(doc_id, params, incluir_embedding)


@router.delete("/knowledge/{doc_id}", response_model=s.KnowledgeOut)
async def deactivate_knowledge(
    doc_id: int,
    service: Svc,
    actor: Annotated[CurrentUser, perm("config:modificacion")],
) -> s.KnowledgeOut:
    return await service.deactivate_knowledge(actor, doc_id)


@router.get("/status", response_model=s.AIStatus)
async def ai_status(
    service: Svc, _: Annotated[CurrentUser, perm("config:consulta")]
) -> s.AIStatus:
    return await service.status()


@router.get("/sentiment/{emprendedor_id}", response_model=list[s.SentimentPoint])
async def sentiment(
    emprendedor_id: int,
    service: Svc,
    _: Annotated[CurrentUser, Depends(require_staff_permission("ia:consulta"))],
) -> list[s.SentimentPoint]:
    return await service.sentiment_series(emprendedor_id)


@router.post("/sentiment/sync", response_model=s.SentimentSyncResult)
async def sync_sentiment(
    body: s.SentimentSync,
    service: Svc,
    user: Annotated[CurrentUser, perm("ia:registro")],
) -> s.SentimentSyncResult:
    """Animo de los mensajes al coach local del celular: solo la clasificacion."""
    return await service.sync_sentiment(user, body)


@router.get("/wellbeing", response_model=s.WellbeingReport)
async def wellbeing(
    service: Svc,
    actor: Annotated[CurrentUser, Depends(require_staff_permission("ia:consulta"))],
    desde: date | None = None,
    hasta: date | None = None,
) -> s.WellbeingReport:
    """Animo de los emprendedores (indice, emocion y tema), sin texto de sus mensajes."""
    return await service.wellbeing(actor, desde, hasta)


@router.get("/wellbeing/{emprendedor_id}", response_model=s.WellbeingDetail)
async def wellbeing_detail(
    emprendedor_id: int,
    service: Svc,
    actor: Annotated[CurrentUser, Depends(require_staff_permission("ia:consulta"))],
    desde: date | None = None,
    hasta: date | None = None,
) -> s.WellbeingDetail:
    return await service.wellbeing_detail(actor, emprendedor_id, desde, hasta)
