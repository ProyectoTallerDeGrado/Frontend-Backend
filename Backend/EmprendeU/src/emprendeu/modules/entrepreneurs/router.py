"""HTTP de entrepreneurs."""

from typing import Annotated

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.config import get_settings
from emprendeu.core.errors import TooManyRequests
from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.db.session import get_session
from emprendeu.modules.entrepreneurs.dependencies import get_application_limiter
from emprendeu.modules.entrepreneurs.schemas import (
    ApplicationAdmit,
    ApplicationAdmitted,
    ApplicationCreate,
    ApplicationOut,
    ApplicationReceived,
    ApplicationReject,
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
from emprendeu.modules.ventures import VentureService

router = APIRouter(prefix="/entrepreneurs", tags=["entrepreneurs"])
applications_router = APIRouter(prefix="/applications", tags=["applications"])

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


# --- postulaciones (CU26) -------------------------------------------------------------

CanDecide = Annotated[
    CurrentUser, Depends(require_staff_permission("emprendedores:registro"))
]


@applications_router.post(
    "", response_model=ApplicationReceived, status_code=status.HTTP_201_CREATED
)
async def submit_application(
    body: ApplicationCreate, request: Request, session: SessionDep
) -> ApplicationReceived:
    """Formulario publico (sin sesion). Limitado por IP y con campo trampa."""
    limiter = get_application_limiter()
    key = request.client.host if request.client else "desconocida"
    if get_settings().application_trust_forwarded_for:
        forwarded = request.headers.get("x-forwarded-for", "").split(",")[0].strip()
        key = forwarded or key
    if limiter.is_blocked(key):
        raise TooManyRequests(
            "Demasiadas postulaciones desde esta conexion. Intenta mas tarde.",
            details={"retry_after": limiter.retry_after(key)},
        )
    limiter.hit(key)
    await EntrepreneurService(session).submit_application(body)
    return ApplicationReceived()


@applications_router.get("", response_model=Page[ApplicationOut])
async def list_applications(
    params: PageParamsDep,
    session: SessionDep,
    _: CanRead,
    estado: str | None = None,
    q: str | None = None,
) -> Page[ApplicationOut]:
    items, total = await EntrepreneurService(session).list_applications(
        params, estado, q
    )
    return Page[ApplicationOut].build(items, params, total)


@applications_router.get("/{postulacion_id}", response_model=ApplicationOut)
async def get_application(
    postulacion_id: int, session: SessionDep, _: CanRead
) -> ApplicationOut:
    return await EntrepreneurService(session).get_application(postulacion_id)


@applications_router.post("/{postulacion_id}/admit", response_model=ApplicationAdmitted)
async def admit_application(
    postulacion_id: int,
    body: ApplicationAdmit,
    session: SessionDep,
    actor: CanDecide,
) -> ApplicationAdmitted:
    """Crea usuario, emprendedor y emprendimiento en una sola transaccion."""
    temporary = await VentureService(session).admit_application(
        actor, postulacion_id, body.observaciones
    )
    out = await EntrepreneurService(session).get_application(postulacion_id)
    return ApplicationAdmitted(**out.model_dump(), temporary_password=temporary)


@applications_router.post("/{postulacion_id}/reject", response_model=ApplicationOut)
async def reject_application(
    postulacion_id: int,
    body: ApplicationReject,
    session: SessionDep,
    actor: CanDecide,
) -> ApplicationOut:
    return await EntrepreneurService(session).reject_application(
        actor.usuario_id, postulacion_id, body.observaciones
    )
