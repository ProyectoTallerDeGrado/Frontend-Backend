"""HTTP de alerts (prefijo /alerts)."""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.db.session import get_session
from emprendeu.modules.alerts import schemas as s
from emprendeu.modules.alerts.service import AlertService
from emprendeu.modules.users import (
    CurrentUser,
    require_permission,
    require_staff_permission,
)

router = APIRouter(prefix="/alerts", tags=["alerts"])


def _svc(session: Annotated[AsyncSession, Depends(get_session)]) -> AlertService:
    return AlertService(session)


Svc = Annotated[AlertService, Depends(_svc)]


def perm(name: str) -> object:
    return Depends(require_permission(name))


def staff(name: str) -> object:
    """Permiso del rol Y ser personal: un emprendedor tiene `seguimiento:*` sobre lo suyo."""
    return Depends(require_staff_permission(name))


@router.get("/settings", response_model=s.SettingsOut)
async def get_settings(
    service: Svc, _: Annotated[CurrentUser, perm("config:consulta")]
) -> s.SettingsOut:
    return await service.get_settings()


@router.put("/settings", response_model=s.SettingsOut)
async def put_settings(
    body: s.SettingsUpdate,
    service: Svc,
    actor: Annotated[CurrentUser, perm("config:modificacion")],
) -> s.SettingsOut:
    return await service.update_settings(actor, body)


@router.get("", response_model=Page[s.AlertOut])
async def list_alerts(
    params: PageParamsDep,
    service: Svc,
    user: Annotated[CurrentUser, staff("seguimiento:consulta")],
    estado: str | None = None,
    tipo: str | None = None,
) -> Page[s.AlertOut]:
    items, total = await service.list(user, params, estado, tipo)
    return Page[s.AlertOut].build(items, params, total)


@router.get("/{alerta_id}", response_model=s.AlertOut)
async def get_alert(
    alerta_id: int,
    service: Svc,
    user: Annotated[CurrentUser, staff("seguimiento:consulta")],
) -> s.AlertOut:
    return await service.get(user, alerta_id)


@router.patch("/{alerta_id}", response_model=s.AlertOut)
async def update_alert(
    alerta_id: int,
    body: s.AlertUpdate,
    service: Svc,
    actor: Annotated[CurrentUser, staff("seguimiento:registro")],
) -> s.AlertOut:
    return await service.update(actor, alerta_id, body)


@router.post("/evaluate", response_model=s.EvaluationResult)
async def evaluate(
    service: Svc, actor: Annotated[CurrentUser, perm("config:administrativo")]
) -> s.EvaluationResult:
    """Ejecuta la deteccion ahora (tambien corre por cron: ver `jobs.py`)."""
    return await service.evaluate(actor.usuario_id)
