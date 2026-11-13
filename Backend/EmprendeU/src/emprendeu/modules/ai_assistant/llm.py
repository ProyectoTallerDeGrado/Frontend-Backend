"""Cliente de modelos de lenguaje (Ollama) detras de una interfaz minima.

Los servicios dependen de `LLMClient`, no de Ollama: en tests se inyecta un
doble y, si mas adelante se cambia de proveedor, solo cambia esta clase.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Protocol

import httpx

from emprendeu.core.config import get_settings
from emprendeu.modules.ai_assistant.exceptions import AIUnavailable


class LLMClient(Protocol):
    async def embed(self, texts: list[str]) -> list[list[float]]: ...

    async def chat(
        self,
        system: str,
        question: str,
        history: list[tuple[str, str]] | None = None,
    ) -> str: ...

    async def ping(self) -> bool: ...


class OllamaClient:
    def __init__(
        self, base_url: str, embed_model: str, chat_model: str, timeout: float
    ) -> None:
        self._base = base_url.rstrip("/")
        self._embed_model = embed_model
        self._chat_model = chat_model
        self._timeout = timeout

    async def _post(self, path: str, payload: dict) -> dict:
        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                response = await client.post(f"{self._base}{path}", json=payload)
                response.raise_for_status()
                return response.json()
        except (httpx.HTTPError, ValueError) as exc:
            raise AIUnavailable from exc

    async def embed(self, texts: list[str]) -> list[list[float]]:
        data = await self._post(
            "/api/embed", {"model": self._embed_model, "input": texts}
        )
        embeddings = data.get("embeddings")
        if not isinstance(embeddings, list) or len(embeddings) != len(texts):
            raise AIUnavailable("Respuesta de embeddings invalida.")
        return embeddings

    async def chat(
        self,
        system: str,
        question: str,
        history: list[tuple[str, str]] | None = None,
    ) -> str:
        """`history`: turnos previos como (`user`|`assistant`, texto), del mas viejo al mas nuevo."""
        data = await self._post(
            "/api/chat",
            {
                "model": self._chat_model,
                "stream": False,
                "messages": [
                    {"role": "system", "content": system},
                    *({"role": role, "content": text} for role, text in history or []),
                    {"role": "user", "content": question},
                ],
            },
        )
        content = (data.get("message") or {}).get("content")
        if not content:
            raise AIUnavailable("El modelo no devolvio respuesta.")
        return str(content).strip()

    async def ping(self) -> bool:
        try:
            async with httpx.AsyncClient(timeout=3.0) as client:
                return (await client.get(f"{self._base}/api/tags")).is_success
        except httpx.HTTPError:
            return False


def get_llm() -> LLMClient:
    """Dependencia de FastAPI para inyectar el cliente (sobreescribible en tests)."""
    return get_llm_client()


@lru_cache
def get_llm_client() -> LLMClient:
    s = get_settings()
    return OllamaClient(
        s.ollama_base_url,
        s.ollama_embed_model,
        s.ollama_chat_model,
        s.ollama_timeout_seconds,
    )
