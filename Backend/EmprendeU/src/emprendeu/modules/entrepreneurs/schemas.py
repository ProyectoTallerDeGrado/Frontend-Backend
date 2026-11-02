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


class EntrepreneurCreate(BaseModel):
    """Alta de un emprendedor por la coordinacion (crea usuario y perfil juntos)."""

    nombre_completo: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=1, max_length=280)
    ]
    email: Annotated[
        str,
        StringConstraints(
            strip_whitespace=True,
            to_lower=True,
            max_length=254,
            pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
        ),
    ]
    documento_identidad: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=3, max_length=50)
    ]
    # Si se omite, el servidor genera una temporal y la devuelve una sola vez.
    password: Annotated[str, StringConstraints(min_length=8, max_length=128)] | None = (
        None
    )


class EntrepreneurCreated(EntrepreneurOut):
    temporary_password: str | None = None
