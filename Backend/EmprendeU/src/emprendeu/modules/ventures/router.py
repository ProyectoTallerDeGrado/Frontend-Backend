"""HTTP de ventures: /stages, /ventures y /needs."""

from typing import Annotated, Literal

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.db.session import get_session
from emprendeu.modules.users import (
    CurrentUser,
    CurrentUserDep,
    require_permission,
    require_staff_permission,
)
from emprendeu.modules.ventures import schemas as s
from emprendeu.modules.ventures.service import VentureService

router = APIRouter(tags=["ventures"])

SessionDep = Annotated[AsyncSession, Depends(get_session)]


def _svc(session: SessionDep) -> VentureService:
    return VentureService(session)


Svc = Annotated[VentureService, Depends(_svc)]


def perm(name: str) -> object:
    return Depends(require_permission(name))


def staff(name: str) -> object:
    return Depends(require_staff_permission(name))


# --- etapas ---------------------------------------------------------------


@router.get("/stages", response_model=list[s.StageOut])
async def list_stages(service: Svc, _: CurrentUserDep) -> list[s.StageOut]:
    return await service.list_stages()


@router.patch("/stages/{etapa_id}", response_model=s.StageOut)
async def update_stage(
    etapa_id: int,
    body: s.StageUpdate,
    service: Svc,
    actor: Annotated[CurrentUser, perm("config:modificacion")],
) -> s.StageOut:
    return await service.set_stage_state(actor, etapa_id, body.estado)


# --- emprendimientos ------------------------------------------------------


@router.get("/ventures", response_model=Page[s.VentureOut])
async def list_ventures(
    params: PageParamsDep,
    service: Svc,
    _: Annotated[CurrentUser, staff("emprendedores:consulta")],
    q: str | None = None,
    estado: str | None = None,
) -> Page[s.VentureOut]:
    items, total = await service.list(params, q, estado)
    return Page[s.VentureOut].build(items, params, total)


@router.post(
    "/ventures", response_model=s.VentureOut, status_code=status.HTTP_201_CREATED
)
async def create_venture(
    body: s.VentureCreate,
    service: Svc,
    user: Annotated[CurrentUser, perm("emprendedores:registro")],
) -> s.VentureOut:
    return await service.create(user, body)


@router.get("/ventures/me", response_model=list[s.VentureOut])
async def my_ventures(service: Svc, user: CurrentUserDep) -> list[s.VentureOut]:
    return await service.mine(user)


@router.get("/ventures/{emprendimiento_id}", response_model=s.VentureOut)
async def get_venture(
    emprendimiento_id: int, service: Svc, user: CurrentUserDep
) -> s.VentureOut:
    return await service.get(user, emprendimiento_id)


@router.patch("/ventures/{emprendimiento_id}", response_model=s.VentureOut)
async def update_venture(
    emprendimiento_id: int, body: s.VentureUpdate, service: Svc, user: CurrentUserDep
) -> s.VentureOut:
    return await service.update(user, emprendimiento_id, body)


# --- integrantes (CU05) ---------------------------------------------------


@router.get("/ventures/{emprendimiento_id}/members", response_model=list[s.MemberOut])
async def list_members(
    emprendimiento_id: int, service: Svc, user: CurrentUserDep
) -> list[s.MemberOut]:
    return await service.list_members(user, emprendimiento_id)


@router.post(
    "/ventures/{emprendimiento_id}/members",
    response_model=list[s.MemberOut],
    status_code=status.HTTP_201_CREATED,
)
async def add_member(
    emprendimiento_id: int,
    body: s.MemberIn,
    service: Svc,
    user: Annotated[CurrentUser, staff("emprendedores:modificacion")],
) -> list[s.MemberOut]:
    return await service.add_member(user, emprendimiento_id, body)


@router.delete(
    "/ventures/{emprendimiento_id}/members/{emprendedor_id}",
    response_model=list[s.MemberOut],
)
async def remove_member(
    emprendimiento_id: int,
    emprendedor_id: int,
    service: Svc,
    user: Annotated[CurrentUser, staff("emprendedores:modificacion")],
) -> list[s.MemberOut]:
    return await service.remove_member(user, emprendimiento_id, emprendedor_id)


@router.put("/ventures/{emprendimiento_id}/stage", response_model=s.VentureOut)
async def change_stage(
    emprendimiento_id: int,
    body: s.StageChange,
    service: Svc,
    user: Annotated[CurrentUser, perm("seguimiento:modificacion")],
) -> s.VentureOut:
    return await service.change_stage(user, emprendimiento_id, body)


@router.get(
    "/ventures/{emprendimiento_id}/stages", response_model=list[s.VentureStageOut]
)
async def stage_history(
    emprendimiento_id: int, service: Svc, user: CurrentUserDep
) -> list[s.VentureStageOut]:
    return await service.stage_history(user, emprendimiento_id)


# --- hitos ----------------------------------------------------------------


@router.get(
    "/ventures/{emprendimiento_id}/milestones", response_model=list[s.MilestoneOut]
)
async def list_milestones(
    emprendimiento_id: int, service: Svc, user: CurrentUserDep
) -> list[s.MilestoneOut]:
    return await service.list_milestones(user, emprendimiento_id)


@router.post(
    "/ventures/{emprendimiento_id}/milestones",
    response_model=s.MilestoneOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_milestone(
    emprendimiento_id: int, body: s.MilestoneCreate, service: Svc, user: CurrentUserDep
) -> s.MilestoneOut:
    return await service.create_milestone(user, emprendimiento_id, body)


@router.patch("/milestones/{hito_id}", response_model=s.MilestoneOut)
async def update_milestone(
    hito_id: int, body: s.MilestoneUpdate, service: Svc, user: CurrentUserDep
) -> s.MilestoneOut:
    return await service.update_milestone(user, hito_id, body)


# --- necesidades ----------------------------------------------------------


@router.get("/needs", response_model=list[s.NeedOut])
async def list_needs(service: Svc, _: CurrentUserDep) -> list[s.NeedOut]:
    return await service.list_needs()


@router.post("/needs", response_model=s.NeedOut, status_code=status.HTTP_201_CREATED)
async def create_need(
    body: s.NeedCreate,
    service: Svc,
    _: Annotated[CurrentUser, perm("config:registro")],
) -> s.NeedOut:
    return await service.create_need(body)


@router.get(
    "/ventures/{emprendimiento_id}/needs", response_model=list[s.VentureNeedOut]
)
async def list_venture_needs(
    emprendimiento_id: int, service: Svc, user: CurrentUserDep
) -> list[s.VentureNeedOut]:
    return await service.list_venture_needs(user, emprendimiento_id)


@router.post(
    "/ventures/{emprendimiento_id}/needs",
    response_model=s.VentureNeedOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_venture_need(
    emprendimiento_id: int,
    body: s.VentureNeedCreate,
    service: Svc,
    user: CurrentUserDep,
) -> s.VentureNeedOut:
    return await service.add_venture_need(user, emprendimiento_id, body)


@router.get("/venture-needs", response_model=Page[s.VentureNeedInboxItem])
async def needs_inbox(
    params: PageParamsDep,
    service: Svc,
    _: Annotated[CurrentUser, staff("seguimiento:consulta")],
    estado: Literal["detectada", "resuelta"] | None = None,
    tipo: Literal["necesidad", "dificultad"] | None = None,
    emprendimiento_id: int | None = None,
) -> Page[s.VentureNeedInboxItem]:
    items, total = await service.list_needs_inbox(
        params, estado, tipo, emprendimiento_id
    )
    return Page[s.VentureNeedInboxItem].build(items, params, total)


@router.patch("/venture-needs/{row_id}/resolve", response_model=s.VentureNeedOut)
async def resolve_venture_need(
    row_id: int, service: Svc, user: CurrentUserDep
) -> s.VentureNeedOut:
    return await service.resolve_venture_need(user, row_id)
