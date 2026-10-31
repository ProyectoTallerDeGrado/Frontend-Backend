"""Servicio de auditoria: registra acciones sensibles y las consulta."""

from __future__ import annotations

import csv
import io
from datetime import UTC, date
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import PageParams
from emprendeu.modules.audit.catalog import category_of, label_for
from emprendeu.modules.audit.models import Bitacora
from emprendeu.modules.audit.repository import AuditRepository
from emprendeu.modules.audit.schemas import AuditOut

EXPORT_LIMIT = 10_000


def _to_out(entry: Bitacora, actor: str | None) -> AuditOut:
    data = entry.datos_nuevos or {}
    action = entry.accion or ""
    return AuditOut(
        bitacora_id=entry.bitacora_id,
        fecha=entry.fecha,
        actor_id=entry.usuario_id,
        actor=actor,
        accion=action,
        categoria=category_of(action),
        descripcion=label_for(action),
        objeto=data.get("objeto"),
        resultado=data.get("resultado", "exitoso"),
    )


class AuditService:
    """El resto de modulos solo usan `record`. No hace commit: lo hace quien llama."""

    def __init__(self, session: AsyncSession) -> None:
        self._repo = AuditRepository(session)

    async def record(
        self,
        actor_id: int | None,
        action: str,
        objeto: str | None = None,
        *,
        resultado: str = "exitoso",
        tabla: str | None = None,
        id_registro: int | str | None = None,
        antes: dict[str, Any] | None = None,
        despues: dict[str, Any] | None = None,
        ip: str | None = None,
    ) -> None:
        await self._repo.add(
            Bitacora(
                accion=action,
                datos_anteriores=antes,
                datos_nuevos={
                    "objeto": objeto,
                    "resultado": resultado,
                    **(despues or {}),
                },
                fecha=self._repo.now(),
                ip=ip,
                tabla=tabla,
                usuario_id=actor_id,
                id_registro=None if id_registro is None else str(id_registro),
            )
        )

    async def list(
        self, params: PageParams, *, categoria: str | None, resultado: str | None
    ) -> tuple[list[AuditOut], int]:
        rows, total = await self._repo.list(
            categoria=categoria,
            resultado=resultado,
            offset=params.offset,
            limit=params.page_size,
        )
        return [_to_out(e, a) for e, a in rows], total

    async def login_days(self, usuario_id: int, limit: int = 200) -> set[date]:
        """Dias distintos (UTC) en que el usuario inicio sesion."""
        return {
            d.astimezone(UTC).date()
            for d in await self._repo.login_dates(usuario_id, limit)
            if d is not None
        }

    async def total(self) -> int:
        return await self._repo.count()

    async def export_csv(self, *, categoria: str | None, resultado: str | None) -> str:
        rows, _ = await self._repo.list(
            categoria=categoria, resultado=resultado, offset=0, limit=EXPORT_LIMIT
        )
        buffer = io.StringIO()
        writer = csv.writer(buffer)
        writer.writerow(
            ["fecha", "actor", "categoria", "accion", "objeto", "resultado"]
        )
        for entry, actor in rows:
            out = _to_out(entry, actor)
            writer.writerow(
                [
                    out.fecha.isoformat() if out.fecha else "",
                    out.actor or "",
                    out.categoria,
                    out.descripcion,
                    out.objeto or "",
                    out.resultado,
                ]
            )
        return buffer.getvalue()
