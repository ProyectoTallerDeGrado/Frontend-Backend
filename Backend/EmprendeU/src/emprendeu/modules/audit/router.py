"""HTTP de auditoria: consulta y exportacion CSV (permiso config:consulta)."""

from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import Response

from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.modules.audit.dependencies import AuditServiceDep
from emprendeu.modules.audit.schemas import AuditOut
from emprendeu.modules.users import CurrentUser, require_permission

router = APIRouter(prefix="/audit", tags=["audit"])

CanRead = Annotated[CurrentUser, Depends(require_permission("config:consulta"))]


@router.get("", response_model=Page[AuditOut])
async def list_audit(
    params: PageParamsDep,
    service: AuditServiceDep,
    _: CanRead,
    categoria: str | None = None,
    resultado: str | None = None,
) -> Page[AuditOut]:
    items, total = await service.list(params, categoria=categoria, resultado=resultado)
    return Page[AuditOut].build(items, params, total)


@router.get("/export")
async def export_audit(
    service: AuditServiceDep,
    _: CanRead,
    categoria: str | None = None,
    resultado: str | None = None,
) -> Response:
    content = await service.export_csv(categoria=categoria, resultado=resultado)
    return Response(
        content=content,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="auditoria.csv"'},
    )
