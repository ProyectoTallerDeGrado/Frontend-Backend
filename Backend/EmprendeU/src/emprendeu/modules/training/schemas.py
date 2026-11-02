"""Esquemas de training."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated, Literal

from pydantic import BaseModel, StringConstraints

Title = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=240)
]


class TrainingCreate(BaseModel):
    titulo: Title
    descripcion: str | None = None
    fecha: datetime | None = None
    modalidad: Annotated[str | None, StringConstraints(max_length=40)] = None
    tipo: Annotated[str | None, StringConstraints(max_length=60)] = None


class TrainingUpdate(BaseModel):
    titulo: Title | None = None
    descripcion: str | None = None
    fecha: datetime | None = None
    modalidad: Annotated[str | None, StringConstraints(max_length=40)] = None
    tipo: Annotated[str | None, StringConstraints(max_length=60)] = None
    estado: Literal["borrador", "publicada", "realizada", "cancelada"] | None = None


class TrainingOut(BaseModel):
    capacitacion_id: int
    titulo: str
    descripcion: str | None
    fecha: datetime | None
    modalidad: str | None
    tipo: str | None
    estado: str | None
    total_inscritos: int
    inscrito: bool | None = None
    # Asistencia de quien consulta: None = pendiente de registrar.
    mi_asistencia: bool | None = None


class ParticipantAdd(BaseModel):
    emprendedor_id: int


class AttendanceUpdate(BaseModel):
    asistio: bool


class ParticipantOut(BaseModel):
    capacitacion_participante_id: int
    emprendedor_id: int
    asistencia: bool | None  # None = pendiente de registrar
    fecha_registro: datetime | None
    nombre: str | None = None
    apellido: str | None = None
    email: str | None = None
    documento_identidad: str | None = None
