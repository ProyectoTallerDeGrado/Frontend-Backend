"""HTTP de entrepreneurs."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.db.session import get_session
from emprendeu.modules.entrepreneurs.schemas import (
    EntrepreneurCreate,
    EntrepreneurCreated,
    EntrepreneurOut,
    EntrepreneurUpdate,
)
from emprendeu.modules.entrepreneurs.service import EntrepreneurService
from emprendeu.modules.users import (
    CurrentUser,
    CurrentUserDep,
    build_user_service,
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


@router.post(
    "", response_model=EntrepreneurCreated, status_code=status.HTTP_201_CREATED
)
async def register_entrepreneur(
    body: EntrepreneurCreate,
    session: SessionDep,
    actor: Annotated[
        CurrentUser, Depends(require_staff_permission("emprendedores:registro"))
    ],
) -> EntrepreneurCreated:
    """CU04: crea usuario y emprendedor en una sola transaccion."""
    user, temporary = await build_user_service(session).register_entrepreneur(
        actor,
        body.nombre_completo,
        body.email,
        body.documento_identidad,
        body.password,
    )
    out = await EntrepreneurService(session).out_for_user(user.usuario_id)
    return EntrepreneurCreated(**out.model_dump(), temporary_password=temporary)


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
