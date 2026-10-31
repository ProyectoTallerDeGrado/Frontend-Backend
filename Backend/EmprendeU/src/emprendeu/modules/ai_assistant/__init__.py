"""Modulo ai_assistant: coach IA con RAG, conversaciones y sentimiento.

API publica: `AssistantService` (`sentiment_drops`), `LLMClient`, `get_llm_client`.
El `router` lo importa `api/v1.py`.
"""

from emprendeu.modules.ai_assistant.llm import (
    LLMClient,
    OllamaClient,
    get_llm,
    get_llm_client,
)
from emprendeu.modules.ai_assistant.models import (
    AnalisisSentimiento,
    ConversacionIa,
    DocumentoConocimiento,
    FragmentoDocumento,
    MensajeIa,
)
from emprendeu.modules.ai_assistant.service import AssistantService

__all__ = [
    "AnalisisSentimiento",
    "AssistantService",
    "ConversacionIa",
    "DocumentoConocimiento",
    "FragmentoDocumento",
    "LLMClient",
    "MensajeIa",
    "OllamaClient",
    "get_llm",
    "get_llm_client",
]
