"""HTTP de entrepreneurs."""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.db.session import get_session
from emprendeu.modules.entrepreneurs.schemas import EntrepreneurOut, EntrepreneurUpdate
from emprendeu.modules.entrepreneurs.service import EntrepreneurService
from emprendeu.modules.users import (
    CurrentUser,
    CurrentUserDep,
    require_staff_permission,
)

router = APIRouter(prefix="/entrepreneurs", tags=["entrepreneurs"])

SessionDep = Annotated[AsyncSession, Depends(get_session)]
CanRead = Annotated[
    CurrentUser, Depends(require_staff_permission("emprendedores:consulta"))
]


@router.get("", response_model=Page[EntrepreneurOut])
async def list_entrepreneurs(
    params: PageParamsDep, session: SessionDep, _: CanRead, q: str | None = None
) -> Page[EntrepreneurOut]:
    items, total = await EntrepreneurService(session).list(params, q)
    return Page[EntrepreneurOut].build(items, params, total)


@router.get("/me", response_model=EntrepreneurOut)
async def my_profile(current: CurrentUserDep, session: SessionDep) -> EntrepreneurOut:
    return await EntrepreneurService(session).me(current.usuario_id)


@router.patch("/me", response_model=EntrepreneurOut)
async def update_my_profile(
    body: EntrepreneurUpdate, current: CurrentUserDep, session: SessionDep
) -> EntrepreneurOut:
    service = EntrepreneurService(session)
    out = await service.update_me(current.usuario_id, body.documento_identidad)
    await session.commit()
    return out


@router.get("/{emprendedor_id}", response_model=EntrepreneurOut)
async def get_entrepreneur(
    emprendedor_id: int, session: SessionDep, _: CanRead
) -> EntrepreneurOut:
    return await EntrepreneurService(session).get(emprendedor_id)
