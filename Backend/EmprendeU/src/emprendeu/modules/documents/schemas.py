"""Esquemas de documents."""

from datetime import datetime

from pydantic import BaseModel


class DocumentOut(BaseModel):
    documento_id: int
    nombre: str
    tipo: str | None
    usuario_id: int
    emprendimiento_id: int | None
    fecha_subida: datetime | None
