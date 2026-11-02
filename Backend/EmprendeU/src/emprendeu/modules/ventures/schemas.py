"""Esquemas del modulo ventures."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated, Literal

from pydantic import BaseModel, StringConstraints

Name = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=160)
]
Title = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=240)
]


class StageOut(BaseModel):
    etapa_id: int
    nombre: str
    descripcion: str | None
    criterios: str | None
    orden: int | None
    estado: str | None


class StageUpdate(BaseModel):
    estado: Literal["activa", "inactiva"]


class VentureCreate(BaseModel):
    nombre: Name
    descripcion: str | None = None
    sector: Annotated[str | None, StringConstraints(max_length=120)] = None
    # Solo el personal lo indica: de quien es el emprendimiento. Un emprendedor crea el suyo.
    emprendedor_id: int | None = None


class VentureUpdate(BaseModel):
    nombre: Name | None = None
    descripcion: str | None = None
    sector: Annotated[str | None, StringConstraints(max_length=120)] = None
    estado: Annotated[str | None, StringConstraints(max_length=40)] = None


class VentureOut(BaseModel):
    emprendimiento_id: int
    nombre: str
    descripcion: str | None
    sector: str | None
    estado: str | None
    fecha_creacion: datetime | None
    etapa_actual: StageOut | None = None


class StageChange(BaseModel):
    etapa_id: int
    observaciones: str | None = None


class VentureStageOut(BaseModel):
    emprendimiento_etapa_id: int
    etapa_id: int
    etapa: str
    estado: str | None
    fecha_inicio: datetime | None
    fecha_fin: datetime | None
    observaciones: str | None


class MilestoneCreate(BaseModel):
    titulo: Title
    descripcion: str | None = None
    fecha_estimada: datetime | None = None


class MilestoneUpdate(BaseModel):
    estado: Literal["pendiente", "cumplido"]


class MilestoneOut(BaseModel):
    hito_id: int
    emprendimiento_id: int
    titulo: str
    descripcion: str | None
    estado: str | None
    fecha_estimada: datetime | None
    fecha_cumplimiento: datetime | None


class NeedCreate(BaseModel):
    nombre: Name
    descripcion: str | None = None


class NeedOut(BaseModel):
    necesidad_id: int
    nombre: str
    descripcion: str | None


class VentureNeedCreate(BaseModel):
    necesidad_id: int
    prioridad: Literal["baja", "media", "alta"] = "media"


class VentureNeedOut(BaseModel):
    emprendimiento_necesidad_id: int
    necesidad_id: int
    necesidad: str
    estado: str | None
    prioridad: str | None
    fecha_detectada: datetime | None
    fecha_resuelta: datetime | None
