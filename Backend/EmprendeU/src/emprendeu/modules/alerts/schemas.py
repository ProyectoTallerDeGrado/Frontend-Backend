"""Esquemas de alerts."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated, Literal

from pydantic import BaseModel, Field


class SettingsOut(BaseModel):
    inactividad_dias: int
    caida_sentimiento_pct: int
    periodos_consecutivos: int
    notificar_coordinador: bool
    notificar_asesor: bool
    alertar_incumplimiento: bool
    fecha_actualizacion: datetime | None


class SettingsUpdate(BaseModel):
    inactividad_dias: Annotated[int, Field(ge=1, le=365)]
    caida_sentimiento_pct: Annotated[int, Field(ge=1, le=100)]
    periodos_consecutivos: Annotated[int, Field(ge=1, le=12)]
    notificar_coordinador: bool
    notificar_asesor: bool
    alertar_incumplimiento: bool


class AlertOut(BaseModel):
    alerta_id: int
    emprendimiento_id: int
    emprendimiento: str | None
    tipo: str | None
    titulo: str
    descripcion: str | None
    prioridad: str | None
    estado: str | None
    fecha_generacion: datetime | None


class AlertUpdate(BaseModel):
    estado: Literal["atendida", "descartada"]


class EvaluationResult(BaseModel):
    creadas: int
    por_tipo: dict[str, int]
