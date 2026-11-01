"""Esquemas del modulo entrepreneurs."""

from datetime import datetime
from typing import Annotated

from pydantic import BaseModel, StringConstraints


class VentureLink(BaseModel):
    emprendimiento_id: int
    rol_en_emprendimiento: str | None


class EntrepreneurOut(BaseModel):
    emprendedor_id: int
    usuario_id: int
    nombre: str | None
    apellido: str | None
    email: str | None
    documento_identidad: str | None
    estado: str | None
    fecha_registro: datetime | None
    emprendimientos: list[VentureLink]


class EntrepreneurUpdate(BaseModel):
    documento_identidad: Annotated[
        str | None, StringConstraints(strip_whitespace=True, max_length=50)
    ] = None
