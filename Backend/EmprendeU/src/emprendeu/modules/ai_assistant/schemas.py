"""Esquemas de ai_assistant."""

from __future__ import annotations

from datetime import date, datetime
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, StringConstraints

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


# Mismas claves que `sentiment.EMOTIONS` / `sentiment.TOPICS` y que los CHECK de la tabla.
Emotion = Literal[
    "motivacion",
    "tranquilidad",
    "neutral",
    "preocupacion",
    "estres",
    "frustracion",
    "desanimo",
]
Topic = Literal[
    "finanzas",
    "ventas_clientes",
    "equipo",
    "tiempo_estudios",
    "producto",
    "tramites",
    "personal",
    "otro",
]
WellbeingLevel = Literal["rojo", "ambar", "verde", "sin_datos"]


class SentimentSyncItem(BaseModel):
    """Resultado de un mensaje analizado en el celular (coach sin internet).

    No hay campo de texto, y `extra="forbid"` rechaza cualquier otro: el mensaje
    no sale del telefono.
    """

    model_config = ConfigDict(extra="forbid")

    referencia_cliente: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=8, max_length=64)
    ]
    fecha: datetime
    indice: Annotated[float, Field(ge=-1, le=1)]
    emocion: Emotion
    tema: Topic
    riesgo: bool = False


class SentimentSync(BaseModel):
    model_config = ConfigDict(extra="forbid")

    items: Annotated[list[SentimentSyncItem], Field(min_length=1, max_length=100)]


class SentimentSyncResult(BaseModel):
    registrados: int
    duplicados: int


class CountOut(BaseModel):
    clave: str
    total: int


class WellbeingRow(BaseModel):
    """Animo de un emprendedor en el periodo. Sin texto de sus mensajes."""

    emprendedor_id: int
    nombre: str
    emprendimientos: list[str]
    nivel: WellbeingLevel
    indice_promedio: float | None
    indice_anterior: float | None  # periodo anterior de igual duracion
    tendencia: Literal["sube", "baja", "estable"] | None
    emocion_principal: Emotion | None
    tema_principal: Topic | None
    mensajes: int
    senales_riesgo: int
    ultima_fecha: datetime | None


class WellbeingReport(BaseModel):
    desde: date
    hasta: date
    # Con menos mensajes que esto no se asigna nivel (`sin_datos`).
    minimo_mensajes: int
    emprendedores: list[WellbeingRow]


class WellbeingDetail(BaseModel):
    desde: date
    hasta: date
    resumen: WellbeingRow
    semanas: list[SentimentPoint]
    emociones: list[CountOut]
    temas: list[CountOut]
    por_origen: list[CountOut]  # servidor | local


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
