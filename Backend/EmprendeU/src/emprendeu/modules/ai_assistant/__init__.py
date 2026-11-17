"""Modulo ai_assistant: coach IA con RAG, conversaciones y sentimiento.

API publica: `AssistantService` (`sentiment_drops`), `LLMClient`, `get_llm_client` y,
para la ayuda del panel web, `HelpLLM`/`get_help_llm` (Gemini).
El `router` lo importa `api/v1.py`.
"""

from emprendeu.modules.ai_assistant.gemini import (
    GeminiClient,
    HelpLLM,
    get_help_llm,
)
from emprendeu.modules.ai_assistant.llm import (
    LLMClient,
    OllamaClient,
    get_llm,
    get_llm_client,
)
from emprendeu.modules.ai_assistant.models import (
    AnalisisSentimiento,
    AyudaUsoDiario,
    ConversacionIa,
    DocumentoConocimiento,
    FragmentoDocumento,
    MensajeIa,
)
from emprendeu.modules.ai_assistant.service import AssistantService

__all__ = [
    "AnalisisSentimiento",
    "AssistantService",
    "AyudaUsoDiario",
    "GeminiClient",
    "HelpLLM",
    "ConversacionIa",
    "DocumentoConocimiento",
    "FragmentoDocumento",
    "LLMClient",
    "MensajeIa",
    "OllamaClient",
    "get_help_llm",
    "get_llm",
    "get_llm_client",
]
