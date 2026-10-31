"""Esquemas de ai_assistant."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated

from pydantic import BaseModel, StringConstraints

Title = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=240)
]


class KnowledgeCreate(BaseModel):
    titulo: Title
    contenido: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]
    fuente: Annotated[str | None, StringConstraints(max_length=300)] = None
    descripcion: str | None = None


class KnowledgeOut(BaseModel):
    documento_conocimiento_id: int
    titulo: str
    descripcion: str | None
    fuente: str | None
    estado: str | None
    fecha_carga: datetime | None
    total_fragmentos: int


class ChatRequest(BaseModel):
    mensaje: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=1, max_length=2000)
    ]
    conversacion_id: int | None = None


class MessageOut(BaseModel):
    mensaje_id: int
    tipo: str | None
    contenido: str
    fecha: datetime | None


class ChatReply(BaseModel):
    conversacion_id: int
    pregunta: MessageOut
    respuesta: MessageOut
    fuente: bool
    fuentes: list[str]
    derivar_mentor: bool


class ConversationOut(BaseModel):
    conversacion_id: int
    fecha_inicio: datetime | None
    fecha_fin: datetime | None
    total_mensajes: int


class SentimentPoint(BaseModel):
    semana: str
    indice_promedio: float
    mensajes: int


class AIStatus(BaseModel):
    ollama_disponible: bool
    documentos_activos: int
