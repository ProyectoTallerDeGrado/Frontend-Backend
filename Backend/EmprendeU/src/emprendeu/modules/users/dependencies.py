"""Dependencias de FastAPI: servicio, usuario actual y control de permisos."""

from collections.abc import Awaitable, Callable
from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.config import get_settings
from emprendeu.core.errors import Forbidden, Unauthorized
from emprendeu.core.ratelimit import SlidingWindowLimiter
from emprendeu.db.session import get_session
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.users.repository import UserRepository
from emprendeu.modules.users.service import CurrentUser, UserService

_bearer = HTTPBearer(auto_error=False, description="JWT de acceso")


_limiter: SlidingWindowLimiter | None = None


def get_login_limiter() -> SlidingWindowLimiter:
    """Limitador de login unico por proceso (se crea al primer uso)."""
    global _limiter  # noqa: PLW0603
    if _limiter is None:
        settings = get_settings()
        _limiter = SlidingWindowLimiter(
            settings.login_max_attempts, settings.login_window_seconds
        )
    return _limiter


def build_user_service(session: AsyncSession) -> UserService:
    return UserService(
        UserRepository(session),
        AuditService(session),
        EntrepreneurService(session),
        get_login_limiter(),
    )


def get_user_service(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> UserService:
    return build_user_service(session)


UserServiceDep = Annotated[UserService, Depends(get_user_service)]


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    service: UserServiceDep,
) -> CurrentUser:
    if credentials is None:
        raise Unauthorized("Falta el token de acceso.")
    return await service.authenticate(credentials.credentials)


CurrentUserDep = Annotated[CurrentUser, Depends(get_current_user)]


def require_staff_permission(
    permission: str,
) -> Callable[..., Awaitable[CurrentUser]]:
    """Como `require_permission` pero excluye al rol emprendedor (solo ve lo suyo)."""

    async def _check(user: CurrentUserDep) -> CurrentUser:
        if not user.can_staff(permission):
            raise Forbidden(
                "No tienes permiso para esta accion.",
                details={"requerido": permission},
            )
        return user

    return _check


def require_permission(permission: str) -> Callable[..., Awaitable[CurrentUser]]:
    """Dependencia que exige un permiso `modulo:accion` y devuelve al usuario."""

    async def _check(user: CurrentUserDep) -> CurrentUser:
        if not user.can(permission):
            raise Forbidden(
                "No tienes permiso para esta accion.",
                details={"requerido": permission},
            )
        return user

    return _check
