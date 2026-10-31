"""HTTP de mentoring (prefijo /mentoring)."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.db.session import get_session
from emprendeu.modules.mentoring import schemas as s
from emprendeu.modules.mentoring.service import MentoringService
from emprendeu.modules.users import (
    CurrentUser,
    CurrentUserDep,
    require_staff_permission,
)

router = APIRouter(prefix="/mentoring", tags=["mentoring"])


def _svc(session: Annotated[AsyncSession, Depends(get_session)]) -> MentoringService:
    return MentoringService(session)


Svc = Annotated[MentoringService, Depends(_svc)]


def staff(name: str) -> object:
    return Depends(require_staff_permission(name))


# --- mentores y agenda -----------------------------------------------------------


@router.get("/mentors", response_model=list[s.MentorOut])
async def list_mentors(
    service: Svc, user: CurrentUserDep, emprendimiento_id: int | None = None
) -> list[s.MentorOut]:
    return await service.list_mentors(user, emprendimiento_id)


@router.put("/mentors/{mentor_id}/profile", response_model=s.MentorOut)
async def set_profile(
    mentor_id: int, body: s.MentorProfileUpdate, service: Svc, user: CurrentUserDep
) -> s.MentorOut:
    return await service.set_profile(user, mentor_id, body)


@router.get(
    "/mentors/{mentor_id}/availability", response_model=list[s.AvailabilityItem]
)
async def get_availability(
    mentor_id: int, service: Svc, _: CurrentUserDep
) -> list[s.AvailabilityItem]:
    return await service.get_availability(mentor_id)


@router.put(
    "/mentors/{mentor_id}/availability", response_model=list[s.AvailabilityItem]
)
async def set_availability(
    mentor_id: int, body: list[s.AvailabilityItem], service: Svc, user: CurrentUserDep
) -> list[s.AvailabilityItem]:
    return await service.set_availability(user, mentor_id, body)


@router.get("/mentors/{mentor_id}/slots", response_model=list[s.SlotOut])
async def slots(
    mentor_id: int, fecha: Annotated[date, Query()], service: Svc, _: CurrentUserDep
) -> list[s.SlotOut]:
    return await service.slots(mentor_id, fecha)


@router.get("/booking-status", response_model=s.BookingStatus)
async def booking_status(
    service: Svc, user: CurrentUserDep, emprendimiento_id: int | None = None
) -> s.BookingStatus:
    return await service.booking_status(user, emprendimiento_id)


# --- sesiones ------------------------------------------------------------------------


@router.post(
    "/sessions", response_model=s.SessionOut, status_code=status.HTTP_201_CREATED
)
async def book_session(
    body: s.SessionCreate, service: Svc, user: CurrentUserDep
) -> s.SessionOut:
    return await service.book(user, body)


@router.get("/sessions/me", response_model=list[s.SessionOut])
async def my_sessions(
    service: Svc,
    user: CurrentUserDep,
    filtro: Annotated[
        str | None, Query(pattern="^(proximas|realizadas|canceladas)$")
    ] = None,
) -> list[s.SessionOut]:
    return await service.my_sessions(user, filtro)


@router.get("/sessions", response_model=Page[s.SessionOut])
async def list_sessions(
    params: PageParamsDep,
    service: Svc,
    _: Annotated[CurrentUser, staff("asesorias:consulta")],
    estado: str | None = None,
) -> Page[s.SessionOut]:
    items, total = await service.list_sessions(params.offset, params.page_size, estado)
    return Page[s.SessionOut].build(items, params, total)


@router.get("/sessions/{sesion_id}", response_model=s.SessionOut)
async def get_session(
    sesion_id: int, service: Svc, user: CurrentUserDep
) -> s.SessionOut:
    return await service.get_session(user, sesion_id)


@router.post("/sessions/{sesion_id}/complete", response_model=s.SessionOut)
async def complete_session(
    sesion_id: int, body: s.SessionComplete, service: Svc, user: CurrentUserDep
) -> s.SessionOut:
    return await service.complete_session(user, sesion_id, body)


@router.post("/sessions/{sesion_id}/cancel", response_model=s.SessionOut)
async def cancel_session(
    sesion_id: int, service: Svc, user: CurrentUserDep
) -> s.SessionOut:
    return await service.cancel_session(user, sesion_id)


# --- compromisos y recomendaciones ----------------------------------------------------


@router.post(
    "/sessions/{sesion_id}/commitments",
    response_model=s.CommitmentOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_commitment(
    sesion_id: int, body: s.CommitmentCreate, service: Svc, user: CurrentUserDep
) -> s.CommitmentOut:
    return await service.create_commitment(user, sesion_id, body)


@router.get("/commitments/me", response_model=list[s.CommitmentOut])
async def my_commitments(
    service: Svc,
    user: CurrentUserDep,
    estado: Annotated[str | None, Query(pattern="^(pendiente|cumplido)$")] = None,
) -> list[s.CommitmentOut]:
    return await service.my_commitments(user, estado)


@router.patch("/commitments/{compromiso_id}", response_model=s.CommitmentOut)
async def update_commitment(
    compromiso_id: int, body: s.CommitmentUpdate, service: Svc, user: CurrentUserDep
) -> s.CommitmentOut:
    return await service.update_commitment(user, compromiso_id, body)


@router.post(
    "/sessions/{sesion_id}/recommendations",
    response_model=s.RecommendationOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_recommendation(
    sesion_id: int, body: s.RecommendationCreate, service: Svc, user: CurrentUserDep
) -> s.RecommendationOut:
    return await service.create_recommendation(user, sesion_id, body)


@router.get("/recommendations/me", response_model=list[s.RecommendationOut])
async def my_recommendations(
    service: Svc, user: CurrentUserDep
) -> list[s.RecommendationOut]:
    return await service.my_recommendations(user)


# --- avances y sincronizacion ---------------------------------------------------------


@router.post("/progress", response_model=s.ProgressOut)
async def log_progress(
    body: s.ProgressCreate, service: Svc, user: CurrentUserDep, response: Response
) -> s.ProgressOut:
    """Idempotente por `referencia_cliente`: 201 si crea, 200 si ya existia."""
    out = await service.log_progress(user, body)
    response.status_code = status.HTTP_201_CREATED if out.creado else status.HTTP_200_OK
    return out


@router.get("/progress", response_model=list[s.ProgressOut])
async def list_progress(
    service: Svc,
    user: CurrentUserDep,
    emprendimiento_id: int | None = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 30,
) -> list[s.ProgressOut]:
    return await service.list_progress(user, emprendimiento_id, limit)


@router.post("/sync", response_model=s.SyncResult)
async def sync(body: s.SyncRequest, service: Svc, user: CurrentUserDep) -> s.SyncResult:
    """Aplica en lote lo registrado sin conexion (avances y compromisos)."""
    return await service.sync(user, body)


# --- asignaciones -----------------------------------------------------------------------


@router.post(
    "/assignments", response_model=s.AssignmentOut, status_code=status.HTTP_201_CREATED
)
async def create_assignment(
    body: s.AssignmentCreate,
    service: Svc,
    actor: Annotated[CurrentUser, staff("asesorias:registro")],
) -> s.AssignmentOut:
    return await service.create_assignment(actor, body)


@router.get("/assignments", response_model=list[s.AssignmentOut])
async def list_assignments(
    service: Svc,
    _: Annotated[CurrentUser, staff("asesorias:consulta")],
    usuario_id: int | None = None,
    emprendimiento_id: int | None = None,
) -> list[s.AssignmentOut]:
    return await service.list_assignments(usuario_id, emprendimiento_id)


@router.get("/assignments/me", response_model=list[s.AssignmentOut])
async def my_assignments(service: Svc, user: CurrentUserDep) -> list[s.AssignmentOut]:
    return await service.list_assignments(user.usuario_id, None)


@router.patch("/assignments/{asignacion_id}/end", response_model=s.AssignmentOut)
async def end_assignment(
    asignacion_id: int,
    service: Svc,
    _: Annotated[CurrentUser, staff("asesorias:registro")],
) -> s.AssignmentOut:
    return await service.end_assignment(asignacion_id)
