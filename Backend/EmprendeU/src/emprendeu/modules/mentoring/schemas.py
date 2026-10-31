"""Esquemas de mentoring."""

from __future__ import annotations

from datetime import date, datetime, time
from decimal import Decimal
from typing import Annotated

from pydantic import BaseModel, Field, StringConstraints

Text = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]


# --- mentores ----------------------------------------------------------------


class MentorOut(BaseModel):
    usuario_id: int
    nombre: str
    especialidad: str | None
    bloqueado: bool
    motivo_bloqueo: str | None


class MentorProfileUpdate(BaseModel):
    especialidad: Annotated[str | None, StringConstraints(max_length=160)] = None
    reto_requerido_id: int | None = None


class AvailabilityItem(BaseModel):
    dia_semana: Annotated[int, Field(ge=0, le=6)]  # 0 = lunes
    hora_inicio: time
    duracion_min: Annotated[int, Field(gt=0, le=480)] = 60


class SlotOut(BaseModel):
    inicio: datetime
    hora: str
    disponible: bool


class BookingStatus(BaseModel):
    habilitado: bool
    motivo: str | None
    etapa: str | None


# --- sesiones ----------------------------------------------------------------


class SessionCreate(BaseModel):
    mentor_id: int
    inicio: datetime
    tema: Annotated[str | None, StringConstraints(max_length=250)] = None
    emprendimiento_id: int | None = None


class SessionComplete(BaseModel):
    observaciones: str | None = None


class ParticipantOut(BaseModel):
    usuario_id: int
    nombre: str | None
    rol: str | None


class SessionOut(BaseModel):
    sesion_id: int
    emprendimiento_id: int
    estado: str | None
    tema: str | None
    modalidad: str | None
    fecha_programada: datetime | None
    fecha_realizada: datetime | None
    observaciones: str | None
    participantes: list[ParticipantOut]
    mentor: str | None
    especialidad: str | None
    total_recomendaciones: int
    total_compromisos: int


# --- compromisos / recomendaciones ------------------------------------------


class CommitmentCreate(BaseModel):
    descripcion: Text
    fecha_limite: datetime | None = None
    usuario_id: int | None = (
        None  # responsable; por defecto el emprendedor de la sesion
    )


class CommitmentUpdate(BaseModel):
    completado: bool
    fecha: datetime | None = None  # momento real (registro sin conexion)


class CommitmentOut(BaseModel):
    compromiso_id: int
    sesion_id: int
    descripcion: str | None
    estado: str | None
    fecha_limite: datetime | None
    fecha_completado: datetime | None


class RecommendationCreate(BaseModel):
    titulo: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=1, max_length=240)
    ]
    contenido: Text


class RecommendationOut(BaseModel):
    recomendacion_id: int
    sesion_id: int | None
    titulo: str
    contenido: str
    estado: str | None
    fecha: datetime | None


# --- avances / sincronizacion ------------------------------------------------


class ProgressCreate(BaseModel):
    observaciones: Text
    porcentaje_avance: Annotated[Decimal | None, Field(ge=0, le=100)] = None
    referencia_cliente: Annotated[str | None, StringConstraints(max_length=64)] = None
    fecha: datetime | None = None
    emprendimiento_id: int | None = None


class ProgressOut(BaseModel):
    seguimiento_id: int
    emprendimiento_id: int
    usuario_id: int
    observaciones: str | None
    porcentaje_avance: Decimal | None
    fecha: datetime | None
    referencia_cliente: str | None
    creado: bool = True


class SyncCommitment(BaseModel):
    compromiso_id: int
    completado: bool
    fecha: datetime | None = None


class SyncRequest(BaseModel):
    avances: Annotated[list[ProgressCreate], Field(max_length=200)] = []
    compromisos: Annotated[list[SyncCommitment], Field(max_length=200)] = []


class SyncResult(BaseModel):
    avances: list[ProgressOut]
    compromisos: list[CommitmentOut]
    errores: list[str]


# --- asignaciones ------------------------------------------------------------


class AssignmentCreate(BaseModel):
    usuario_id: int
    emprendimiento_id: int
    tipo_asignacion: Annotated[str | None, StringConstraints(max_length=80)] = "mentor"


class AssignmentOut(BaseModel):
    asignacion_id: int
    usuario_id: int
    usuario: str | None
    emprendimiento_id: int
    emprendimiento: str | None
    tipo_asignacion: str | None
    estado: str | None
    fecha_inicio: datetime | None
    fecha_fin: datetime | None


class DayQuery(BaseModel):
    fecha: date
