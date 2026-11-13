"""Esquemas del modulo entrepreneurs."""

from datetime import datetime
from typing import Annotated, Literal

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


# --- admision (CU26) ---------------------------------------------------------

Short = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]


class AdmissionCreate(BaseModel):
    """Postulacion publica al programa (sin sesion)."""

    nombre: Annotated[Short, StringConstraints(max_length=160)]
    apellido: Annotated[Short, StringConstraints(max_length=120)]
    email: Annotated[
        str,
        StringConstraints(
            strip_whitespace=True,
            to_lower=True,
            max_length=254,
            pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
        ),
    ]
    telefono: Annotated[str | None, StringConstraints(max_length=35)] = None
    documento_identidad: Annotated[
        str | None, StringConstraints(strip_whitespace=True, max_length=50)
    ] = None
    nombre_emprendimiento: Annotated[Short, StringConstraints(max_length=160)]
    descripcion_emprendimiento: Annotated[
        str | None, StringConstraints(max_length=4000)
    ] = None
    sector: Annotated[str | None, StringConstraints(max_length=120)] = None


class AdmissionReceived(BaseModel):
    """Acuse minimo de la postulacion publica (no expone datos)."""

    postulacion_id: int
    estado: str


class AdmissionOut(BaseModel):
    postulacion_id: int
    nombre: str
    apellido: str
    email: str
    telefono: str | None
    documento_identidad: str | None
    nombre_emprendimiento: str
    descripcion_emprendimiento: str | None
    sector: str | None
    estado: str
    fecha_postulacion: datetime
    fecha_decision: datetime | None
    observaciones_decision: str | None
    decidido_por_id: int | None
    emprendedor_id: int | None
    emprendimiento_id: int | None


class AdmissionDecision(BaseModel):
    """Decision del coordinador: admitir, rechazar o mantener pendiente."""

    decision: Literal["admitida", "rechazada", "pendiente"]
    observaciones: Annotated[
        str | None, StringConstraints(strip_whitespace=True, max_length=2000)
    ] = None


class AdmissionDecided(AdmissionOut):
    # Al admitir se crea la cuenta; la clave temporal se muestra una sola vez.
    temporary_password: str | None = None
