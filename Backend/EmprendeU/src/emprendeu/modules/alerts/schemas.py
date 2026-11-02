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
    # Plazo por defecto de un compromiso sin fecha limite (lo usa mentoring, CU18).
    dias_limite_compromiso: int
    fecha_actualizacion: datetime | None


class SettingsUpdate(BaseModel):
    inactividad_dias: Annotated[int, Field(ge=1, le=365)]
    caida_sentimiento_pct: Annotated[int, Field(ge=1, le=100)]
    periodos_consecutivos: Annotated[int, Field(ge=1, le=12)]
    notificar_coordinador: bool
    notificar_asesor: bool
    alertar_incumplimiento: bool
    # Opcional para no romper a clientes anteriores: si falta, se conserva el valor.
    dias_limite_compromiso: Annotated[int, Field(ge=1, le=90)] | None = None


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
    atendida_por_id: int | None = None
    atendida_por: str | None = None


class AlertUpdate(BaseModel):
    """`revisada`: alguien la vio y sigue pendiente. `atendida` y `descartada` la cierran."""

    estado: Literal["revisada", "atendida", "descartada"]


class EvaluationResult(BaseModel):
    creadas: int
    por_tipo: dict[str, int]
