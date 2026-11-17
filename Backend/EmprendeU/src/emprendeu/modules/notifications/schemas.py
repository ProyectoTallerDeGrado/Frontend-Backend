"""DTO HTTP de notificaciones."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class NotificationOut(BaseModel):
    notificacion_id: int
    tipo: str
    titulo: str
    cuerpo: str
    ruta: str | None
    leida: bool
    creada_en: datetime


class UnreadCount(BaseModel):
    no_leidas: int


class DeviceIn(BaseModel):
    token: str = Field(min_length=10, max_length=512)
    plataforma: Literal["android", "ios"]
