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
    # Emprendimiento al que se asocia una conversacion nueva (si el emprendedor
    # tiene varios). Sin indicarlo, el primero.
    emprendimiento_id: int | None = None


class MessageOut(BaseModel):
    mensaje_id: int
    tipo: str | None
    contenido: str
    fecha: datetime | None


class SourceOut(BaseModel):
    """Documento de la base de conocimiento citado en una respuesta."""

    documento_conocimiento_id: int
    titulo: str


class ChatReply(BaseModel):
    conversacion_id: int
    pregunta: MessageOut
    respuesta: MessageOut
    fuente: bool
    fuentes: list[str]  # titulos, se conserva por compatibilidad con los clientes
    fuentes_detalle: list[SourceOut]
    derivar_mentor: bool


class IndexDocument(BaseModel):
    documento_conocimiento_id: int
    titulo: str
    fuente: str | None
    fecha_carga: datetime | None
    total_fragmentos: int


class KnowledgeIndex(BaseModel):
    """Manifiesto del indice descargable (coach local del movil).

    El cliente compara `documentos` con lo que ya tiene: descarga los nuevos y
    borra los que ya no aparecen. Solo puede reutilizar los vectores si su
    modelo de embeddings es `modelo_embeddings` con `dimension` dimensiones.
    """

    modelo_embeddings: str
    dimension: int
    documentos: list[IndexDocument]


class FragmentOut(BaseModel):
    numero_fragmento: int | None
    contenido: str
    embedding: list[float] | None  # null con `incluir_embedding=false`


class ConversationOut(BaseModel):
    conversacion_id: int
    fecha_inicio: datetime | None
    fecha_fin: datetime | None
    total_mensajes: int


class SentimentPoint(BaseModel):
    semana: str
    indice_promedio: float
    mensajes: int


class KnowledgeGap(BaseModel):
    """Un tema que el coach no pudo responder (anónimo)."""

    tema: str  # la pregunta más reciente del grupo
    veces: int
    ultima_fecha: datetime
    ejemplos: list[str]  # hasta 3 formas distintas de la misma pregunta


class KnowledgeGaps(BaseModel):
    desde: datetime
    hasta: datetime
    # true: agrupadas por similitud con el modelo de embeddings; false: por texto igual
    por_similitud: bool
    temas: list[KnowledgeGap]


class AIStatus(BaseModel):
    ollama_disponible: bool
    documentos_activos: int
