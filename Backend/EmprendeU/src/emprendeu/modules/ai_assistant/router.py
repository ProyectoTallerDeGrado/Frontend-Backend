"""HTTP del coach IA (prefijo /ai)."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.db.session import get_session
from emprendeu.modules.ai_assistant import schemas as s
from emprendeu.modules.ai_assistant.llm import LLMClient, get_llm
from emprendeu.modules.ai_assistant.service import AssistantService
from emprendeu.modules.users import (
    CurrentUser,
    require_permission,
    require_staff_permission,
)

router = APIRouter(prefix="/ai", tags=["ai"])


def _svc(
    session: Annotated[AsyncSession, Depends(get_session)],
    llm: Annotated[LLMClient, Depends(get_llm)],
) -> AssistantService:
    return AssistantService(session, llm)


Svc = Annotated[AssistantService, Depends(_svc)]


def perm(name: str) -> object:
    return Depends(require_permission(name))


@router.post("/chat", response_model=s.ChatReply)
async def chat(
    body: s.ChatRequest,
    service: Svc,
    user: Annotated[CurrentUser, perm("ia:registro")],
) -> s.ChatReply:
    return await service.chat(user, body)


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
    actor: Annotated[CurrentUser, perm("config:administrativo")],
) -> s.KnowledgeOut:
    return await service.ingest(actor, body)


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
