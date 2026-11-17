"""HTTP de notificaciones (prefijo /notifications): bandeja y dispositivos push."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.db.session import get_session
from emprendeu.modules.notifications import schemas as s
from emprendeu.modules.notifications.service import NotificationService
from emprendeu.modules.users import CurrentUserDep

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _svc(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> NotificationService:
    return NotificationService(session)


Svc = Annotated[NotificationService, Depends(_svc)]


@router.get("", response_model=Page[s.NotificationOut])
async def list_notifications(
    user: CurrentUserDep,
    service: Svc,
    params: PageParamsDep,
    solo_no_leidas: Annotated[bool, Query()] = False,
) -> Page[s.NotificationOut]:
    items, total = await service.list(user, solo_no_leidas, params)
    return Page.build(items, params, total)


@router.get("/unread-count", response_model=s.UnreadCount)
async def unread_count(user: CurrentUserDep, service: Svc) -> s.UnreadCount:
    return await service.unread_count(user)


@router.post("/read-all", response_model=s.UnreadCount)
async def mark_all_read(user: CurrentUserDep, service: Svc) -> s.UnreadCount:
    return await service.mark_all_read(user)


@router.post("/{notificacion_id}/read", response_model=s.NotificationOut)
async def mark_read(
    notificacion_id: int, user: CurrentUserDep, service: Svc
) -> s.NotificationOut:
    return await service.mark_read(user, notificacion_id)


@router.put("/devices", status_code=status.HTTP_204_NO_CONTENT)
async def register_device(
    body: s.DeviceIn, user: CurrentUserDep, service: Svc
) -> Response:
    """Registra (o reasigna) el token FCM del celular con la sesion abierta."""
    await service.register_device(user, body)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/devices/{token}", status_code=status.HTTP_204_NO_CONTENT)
async def unregister_device(token: str, user: CurrentUserDep, service: Svc) -> Response:
    """Al cerrar sesion en el celular: deja de enviarle avisos de esta cuenta."""
    await service.unregister_device(user, token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
