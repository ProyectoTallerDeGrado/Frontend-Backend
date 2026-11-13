"""HTTP de gamification: catalogo (web) y camino/perfil (movil)."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.db.session import get_session
from emprendeu.modules.gamification import schemas as s
from emprendeu.modules.gamification.service import GamificationService
from emprendeu.modules.users import CurrentUser, CurrentUserDep, require_permission

router = APIRouter(tags=["gamification"])


def _svc(session: Annotated[AsyncSession, Depends(get_session)]) -> GamificationService:
    return GamificationService(session)


Svc = Annotated[GamificationService, Depends(_svc)]


def perm(name: str) -> object:
    return Depends(require_permission(name))


@router.get("/challenges", response_model=list[s.ChallengeOut])
async def list_challenges(service: Svc, _: CurrentUserDep) -> list[s.ChallengeOut]:
    return await service.list_challenges()


@router.post(
    "/challenges", response_model=s.ChallengeOut, status_code=status.HTTP_201_CREATED
)
async def create_challenge(
    body: s.ChallengeCreate,
    service: Svc,
    actor: Annotated[CurrentUser, perm("config:registro")],
) -> s.ChallengeOut:
    return await service.create_challenge(actor, body)


@router.patch("/challenges/{reto_id}", response_model=s.ChallengeOut)
async def update_challenge(
    reto_id: int,
    body: s.ChallengeUpdate,
    service: Svc,
    actor: Annotated[CurrentUser, perm("config:modificacion")],
) -> s.ChallengeOut:
    return await service.update_challenge(actor, reto_id, body)


@router.get("/badges", response_model=list[s.BadgeOut])
async def list_badges(service: Svc, _: CurrentUserDep) -> list[s.BadgeOut]:
    return await service.list_badges()


@router.patch("/badges/{insignia_id}", response_model=s.BadgeOut)
async def update_badge(
    insignia_id: int,
    body: s.BadgeUpdate,
    service: Svc,
    actor: Annotated[CurrentUser, perm("config:modificacion")],
) -> s.BadgeOut:
    return await service.update_badge(actor, insignia_id, body)


@router.get("/journey", response_model=s.JourneyOut)
async def my_journey(
    service: Svc, user: CurrentUserDep, emprendimiento_id: int | None = None
) -> s.JourneyOut:
    """Camino del emprendimiento propio (o de otro si eres personal autorizado)."""
    return await service.journey(user, emprendimiento_id)


@router.post("/journey/challenges/{reto_id}/complete", response_model=s.CompletionOut)
async def complete_challenge(
    reto_id: int,
    service: Svc,
    user: CurrentUserDep,
    body: s.CompleteChallengeIn | None = None,
    emprendimiento_id: int | None = None,
) -> s.CompletionOut:
    return await service.complete_challenge(user, reto_id, emprendimiento_id, body)


@router.get("/gamification/me", response_model=s.ProfileOut)
async def my_profile(service: Svc, user: CurrentUserDep) -> s.ProfileOut:
    return await service.profile(user)
