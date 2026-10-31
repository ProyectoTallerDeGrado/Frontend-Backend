"""HTTP de indicators (prefijo /indicators)."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.db.session import get_session
from emprendeu.modules.ai_assistant import LLMClient, get_llm
from emprendeu.modules.indicators import schemas as s
from emprendeu.modules.indicators.service import IndicatorService
from emprendeu.modules.users import CurrentUser, CurrentUserDep, require_permission

router = APIRouter(prefix="/indicators", tags=["indicators"])


def _svc(
    session: Annotated[AsyncSession, Depends(get_session)],
    llm: Annotated[LLMClient, Depends(get_llm)],
) -> IndicatorService:
    return IndicatorService(session, llm)


Svc = Annotated[IndicatorService, Depends(_svc)]


def perm(name: str) -> object:
    return Depends(require_permission(name))


@router.get("/overview", response_model=s.Overview)
async def overview(
    service: Svc, _: Annotated[CurrentUser, perm("reportes:consulta")]
) -> s.Overview:
    """Resumen del panel de administracion (KPIs y estado de servicios)."""
    return await service.overview()


@router.get("/types", response_model=list[s.IndicatorTypeOut])
async def list_types(service: Svc, _: CurrentUserDep) -> list[s.IndicatorTypeOut]:
    return await service.list_types()


@router.post(
    "/types", response_model=s.IndicatorTypeOut, status_code=status.HTTP_201_CREATED
)
async def create_type(
    body: s.IndicatorTypeCreate,
    service: Svc,
    _: Annotated[CurrentUser, perm("reportes:registro")],
) -> s.IndicatorTypeOut:
    return await service.create_type(body)


@router.get("/ventures/{emprendimiento_id}/values", response_model=list[s.ValueOut])
async def list_values(
    emprendimiento_id: int, service: Svc, user: CurrentUserDep
) -> list[s.ValueOut]:
    return await service.list_values(user, emprendimiento_id)


@router.post(
    "/ventures/{emprendimiento_id}/values",
    response_model=s.ValueOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_value(
    emprendimiento_id: int, body: s.ValueCreate, service: Svc, user: CurrentUserDep
) -> s.ValueOut:
    return await service.add_value(user, emprendimiento_id, body)
