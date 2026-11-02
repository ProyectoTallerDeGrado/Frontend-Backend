"""HTTP de training (prefijo /training)."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.db.session import get_session
from emprendeu.modules.training import schemas as s
from emprendeu.modules.training.service import TrainingService
from emprendeu.modules.users import (
    CurrentUser,
    CurrentUserDep,
    require_permission,
    require_staff_permission,
)

router = APIRouter(prefix="/training", tags=["training"])


def _svc(session: Annotated[AsyncSession, Depends(get_session)]) -> TrainingService:
    return TrainingService(session)


Svc = Annotated[TrainingService, Depends(_svc)]


def perm(name: str) -> object:
    return Depends(require_permission(name))


def staff(name: str) -> object:
    return Depends(require_staff_permission(name))


@router.get("", response_model=Page[s.TrainingOut])
async def list_trainings(
    params: PageParamsDep, service: Svc, user: CurrentUserDep, estado: str | None = None
) -> Page[s.TrainingOut]:
    items, total = await service.list(user, params, estado)
    return Page[s.TrainingOut].build(items, params, total)


@router.post("", response_model=s.TrainingOut, status_code=status.HTTP_201_CREATED)
async def create_training(
    body: s.TrainingCreate,
    service: Svc,
    user: Annotated[CurrentUser, perm("asesorias:registro")],
) -> s.TrainingOut:
    return await service.create(user, body)


@router.get("/published", response_model=list[s.TrainingOut])
async def published_trainings(
    service: Svc, user: CurrentUserDep
) -> list[s.TrainingOut]:
    """CU29: publicadas, con la inscripcion y la asistencia propias."""
    return await service.published(user)


@router.get("/me", response_model=list[s.TrainingOut])
async def my_trainings(service: Svc, user: CurrentUserDep) -> list[s.TrainingOut]:
    return await service.mine(user)


@router.get("/{capacitacion_id}", response_model=s.TrainingOut)
async def get_training(
    capacitacion_id: int, service: Svc, user: CurrentUserDep
) -> s.TrainingOut:
    return await service.get(user, capacitacion_id)


@router.patch("/{capacitacion_id}", response_model=s.TrainingOut)
async def update_training(
    capacitacion_id: int,
    body: s.TrainingUpdate,
    service: Svc,
    user: Annotated[CurrentUser, perm("asesorias:registro")],
) -> s.TrainingOut:
    return await service.update(user, capacitacion_id, body)


@router.post("/{capacitacion_id}/enroll", response_model=s.TrainingOut)
async def enroll(
    capacitacion_id: int, service: Svc, user: CurrentUserDep
) -> s.TrainingOut:
    return await service.enroll(user, capacitacion_id)


@router.get("/{capacitacion_id}/participants", response_model=list[s.ParticipantOut])
async def participants(
    capacitacion_id: int,
    service: Svc,
    _: Annotated[CurrentUser, staff("asesorias:consulta")],
) -> list[s.ParticipantOut]:
    return await service.participants(capacitacion_id)


@router.post(
    "/{capacitacion_id}/participants",
    response_model=s.ParticipantOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_participant(
    capacitacion_id: int,
    body: s.ParticipantAdd,
    service: Svc,
    user: Annotated[CurrentUser, perm("asesorias:registro")],
) -> s.ParticipantOut:
    return await service.add_participant(user, capacitacion_id, body)


@router.patch(
    "/{capacitacion_id}/participants/{emprendedor_id}", response_model=s.ParticipantOut
)
async def set_attendance(
    capacitacion_id: int,
    emprendedor_id: int,
    body: s.AttendanceUpdate,
    service: Svc,
    user: Annotated[CurrentUser, perm("asesorias:registro")],
) -> s.ParticipantOut:
    return await service.set_attendance(user, capacitacion_id, emprendedor_id, body)
