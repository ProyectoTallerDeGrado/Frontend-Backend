"""Esquemas de gamification."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated, Literal

from pydantic import BaseModel, Field, StringConstraints


class ChallengeOut(BaseModel):
    reto_id: int
    titulo: str
    descripcion: str | None
    tipo: str | None
    etapa_id: int
    etapa: str | None
    orden: int | None
    xp_recompensa: int
    estado: str | None


class ChallengeCreate(BaseModel):
    titulo: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=1, max_length=240)
    ]
    descripcion: str | None = None
    tipo: Annotated[str | None, StringConstraints(max_length=60)] = None
    etapa_id: int
    orden: int | None = None
    xp_recompensa: Annotated[int, Field(ge=0)] = 0


class ChallengeUpdate(BaseModel):
    titulo: Annotated[
        str | None,
        StringConstraints(strip_whitespace=True, min_length=1, max_length=240),
    ] = None
    descripcion: str | None = None
    xp_recompensa: Annotated[int | None, Field(ge=0)] = None
    estado: Literal["activo", "inactivo"] | None = None


class BadgeOut(BaseModel):
    insignia_id: int
    nombre: str
    criterio: str | None
    xp_recompensa: int
    estado: str | None


class BadgeUpdate(BaseModel):
    xp_recompensa: Annotated[int | None, Field(ge=0)] = None
    estado: Literal["activa", "inactiva"] | None = None


class JourneyChallenge(BaseModel):
    reto_id: int
    titulo: str
    descripcion: str | None
    etapa_id: int
    etapa: str | None
    orden: int | None
    xp_recompensa: int
    estado: Literal["cumplido", "en_curso", "bloqueado"]
    fecha_completado: datetime | None


class JourneyStage(BaseModel):
    etapa_id: int
    nombre: str
    estado: Literal["cumplida", "en_curso", "bloqueada"]


class CompletionOut(BaseModel):
    reto_id: int
    xp_otorgado: int
    xp_total: int
    nivel: int
    subio_de_nivel: bool
    insignias_nuevas: list[str]


class BadgeProgress(BaseModel):
    insignia_id: int
    nombre: str
    criterio: str | None
    xp_recompensa: int
    obtenida: bool
    fecha_obtenida: datetime | None


class XpMovement(BaseModel):
    motivo: str | None
    cantidad: int
    fecha: datetime | None


class ProfileOut(BaseModel):
    xp_total: int
    nivel: int
    xp_siguiente_nivel: int | None
    xp_faltante: int | None
    progreso_pct: float
    insignias: list[BadgeProgress]
    historial: list[XpMovement]


class JourneyOut(BaseModel):
    emprendimiento_id: int
    xp_total: int
    nivel: int
    xp_siguiente_nivel: int | None
    xp_faltante: int | None
    progreso_pct: float
    etapas: list[JourneyStage]
    retos: list[JourneyChallenge]
    insignias: list[BadgeProgress]
    historial: list[XpMovement]
