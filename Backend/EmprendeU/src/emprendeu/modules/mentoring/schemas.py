"""Esquemas de mentoring."""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import BaseModel, Field, StringConstraints, model_validator

Text = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]


# --- mentores ----------------------------------------------------------------


class MentorOut(BaseModel):
    usuario_id: int
    nombre: str
    especialidad: str | None
    habilitado: bool = False
    bloqueado: bool
    motivo_bloqueo: str | None


class MentorEnable(BaseModel):
    habilitado: bool


class MentorProfileUpdate(BaseModel):
    especialidad: Annotated[str | None, StringConstraints(max_length=160)] = None
    reto_requerido_id: int | None = None


class AvailabilityItem(BaseModel):
    """Intervalo concreto en que el mentor atiende (CU15)."""

    fecha_inicio: datetime
    fecha_fin: datetime
    estado: Literal["disponible", "bloqueado", "reservado"] = "disponible"

    @model_validator(mode="after")
    def _fin_despues_de_inicio(self) -> AvailabilityItem:
        if self.fecha_fin <= self.fecha_inicio:
            raise ValueError("fecha_fin debe ser posterior a fecha_inicio")
        return self


class AvailabilityOut(AvailabilityItem):
    disponibilidad_id: int


class AvailabilityUpdate(BaseModel):
    """Cambio parcial de un horario; lo que no se envia se conserva."""

    fecha_inicio: datetime | None = None
    fecha_fin: datetime | None = None
    estado: Literal["disponible", "bloqueado", "reservado"] | None = None


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


Modality = Literal["presencial", "virtual", "hibrida"]


class SessionComplete(BaseModel):
    """Datos de la sesion que ya ocurrio (CU16). Todo es opcional: sin fecha, ahora."""

    observaciones: str | None = None
    fecha_realizada: datetime | None = None
    tema: Annotated[str | None, StringConstraints(max_length=250)] = None
    modalidad: Modality | None = None


class SessionRegister(BaseModel):
    """Sesion realizada que no se agendo en la app (CU16)."""

    emprendimiento_id: int
    fecha_realizada: datetime
    tema: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=1, max_length=250)
    ]
    modalidad: Modality = "presencial"
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
    emprendimiento: str | None = None
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


class CommitmentRegister(BaseModel):
    """Compromiso de un emprendimiento, con o sin sesion (CU18)."""

    emprendimiento_id: int
    sesion_id: int | None = None
    descripcion: Text
    usuario_id: int  # responsable
    fecha_limite: datetime | None = None  # sin fecha: hoy + dias_limite_compromiso


class CommitmentOut(BaseModel):
    compromiso_id: int
    emprendimiento_id: int | None = None
    responsable_id: int | None = None
    sesion_id: int | None
    descripcion: str | None
    estado: str | None
    fecha_limite: datetime | None
    fecha_completado: datetime | None


class RecommendationCreate(BaseModel):
    titulo: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=1, max_length=240)
    ]
    contenido: Text


class RecommendationRegister(BaseModel):
    """Recomendacion para un emprendimiento, opcionalmente de una sesion (CU17)."""

    emprendimiento_id: int
    sesion_id: int | None = None
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


# --- historial del emprendimiento (CU19) ----------------------------------------


class HistoryEvent(BaseModel):
    """Un hecho en la vida del emprendimiento (sesion, avance, hito, etc.)."""

    tipo: Literal["sesion", "avance", "hito", "recomendacion", "compromiso", "etapa"]
    referencia_id: int
    fecha: datetime | None  # los hitos sin ninguna fecha quedan al final
    titulo: str
    detalle: str | None
    estado: str | None
    autor: str | None
