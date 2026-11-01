"""Esquemas de la bitacora de auditoria."""

from datetime import datetime

from pydantic import BaseModel


class AuditOut(BaseModel):
    bitacora_id: int
    fecha: datetime | None
    actor_id: int | None
    actor: str | None
    accion: str
    categoria: str
    descripcion: str
    objeto: str | None
    resultado: str
