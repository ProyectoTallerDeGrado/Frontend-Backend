"""HTTP de indicators (prefijo /indicators)."""

from datetime import date
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query, status
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.xlsx_export import XLSX_MEDIA_TYPE
from emprendeu.db.session import get_session
from emprendeu.modules.ai_assistant import LLMClient, get_llm
from emprendeu.modules.indicators import schemas as s
from emprendeu.modules.indicators.service import IndicatorService
from emprendeu.modules.users import (
    CurrentUser,
    CurrentUserDep,
    require_permission,
    require_staff_permission,
)

router = APIRouter(prefix="/indicators", tags=["indicators"])


def _svc(
    session: Annotated[AsyncSession, Depends(get_session)],
    llm: Annotated[LLMClient, Depends(get_llm)],
) -> IndicatorService:
    return IndicatorService(session, llm)


Svc = Annotated[IndicatorService, Depends(_svc)]


def perm(name: str) -> object:
    return Depends(require_permission(name))


def staff(name: str) -> object:
    return Depends(require_staff_permission(name))


@router.get("/overview", response_model=s.Overview)
async def overview(
    service: Svc, _: Annotated[CurrentUser, perm("reportes:consulta")]
) -> s.Overview:
    """Resumen del panel de administracion (KPIs y estado de servicios)."""
    return await service.overview()


@router.get("/health", response_model=s.HealthReport)
async def health(
    service: Svc,
    user: Annotated[CurrentUser, staff("seguimiento:consulta")],
    etapa_id: int | None = None,
) -> s.HealthReport:
    """Puntaje de salud por emprendimiento activo, del más urgente al menos."""
    return await service.health(user, etapa_id)


@router.get("/dashboard", response_model=s.Dashboard)
async def dashboard(
    service: Svc,
    _: Annotated[CurrentUser, staff("reportes:consulta")],
    desde: date | None = None,
    hasta: date | None = None,
    etapa_id: int | None = None,
) -> s.Dashboard:
    """Dashboard ejecutivo de emprendimientos, por periodo y etapa (solo lectura)."""
    return await service.dashboard(desde, hasta, etapa_id)


@router.get("/reports/{kind}", response_model=s.ReportOut)
async def report(
    kind: s.ReportKind,
    service: Svc,
    _: Annotated[CurrentUser, staff("reportes:consulta")],
    desde: date | None = None,
    hasta: date | None = None,
    etapa_id: int | None = None,
    limit: Annotated[int, Query(ge=1, le=500)] = 50,
) -> s.ReportOut:
    """Vista previa del reporte (las primeras `limit` filas y el total)."""
    return await service.report(kind, desde, hasta, etapa_id, limit)


@router.get("/reports/{kind}/export")
async def export_report(
    kind: s.ReportKind,
    service: Svc,
    actor: Annotated[CurrentUser, staff("reportes:consulta")],
    desde: date | None = None,
    hasta: date | None = None,
    etapa_id: int | None = None,
    formato: Annotated[Literal["csv", "xlsx"], Query()] = "csv",
) -> Response:
    content = await service.export_report(actor, kind, desde, hasta, etapa_id, formato)
    return Response(
        content=content,
        media_type=XLSX_MEDIA_TYPE if formato == "xlsx" else "text/csv; charset=utf-8",
        headers={
            "Content-Disposition": f'attachment; filename="reporte-{kind}.{formato}"'
        },
    )


@router.get("/types", response_model=list[s.IndicatorTypeOut])
async def list_types(service: Svc, _: CurrentUserDep) -> list[s.IndicatorTypeOut]:
    return await service.list_types()


@router.post(
    "/types", response_model=s.IndicatorTypeOut, status_code=status.HTTP_201_CREATED
)
async def create_type(
    body: s.IndicatorTypeCreate,
    service: Svc,
    _: Annotated[CurrentUser, perm("reportes:registro")],
) -> s.IndicatorTypeOut:
    return await service.create_type(body)


@router.get("/ventures/{emprendimiento_id}/values", response_model=list[s.ValueOut])
async def list_values(
    emprendimiento_id: int, service: Svc, user: CurrentUserDep
) -> list[s.ValueOut]:
    return await service.list_values(user, emprendimiento_id)


@router.post(
    "/ventures/{emprendimiento_id}/values",
    response_model=s.ValueOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_value(
    emprendimiento_id: int, body: s.ValueCreate, service: Svc, user: CurrentUserDep
) -> s.ValueOut:
    return await service.add_value(user, emprendimiento_id, body)
