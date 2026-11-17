"""Cliente de Google Gemini para el asistente de ayuda del panel web.

Solo genera texto (no embeddings): el coach de los emprendedores sigue en Ollama
(`llm.py`). Los servicios dependen de `HelpLLM`; en tests se inyecta un doble con
`dependency_overrides[get_help_llm]`.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Protocol

import httpx

from emprendeu.core.config import get_settings
from emprendeu.modules.ai_assistant.exceptions import AIUnavailable

GEMINI_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
)


class HelpLLM(Protocol):
    @property
    def configured(self) -> bool: ...

    async def chat(
        self,
        system: str,
        question: str,
        history: list[tuple[str, str]] | None = None,
    ) -> str: ...


class GeminiClient:
    def __init__(self, api_key: str, model: str, timeout: float) -> None:
        self._api_key = api_key
        self._model = model
        self._timeout = timeout

    @property
    def configured(self) -> bool:
        return bool(self._api_key)

    async def chat(
        self,
        system: str,
        question: str,
        history: list[tuple[str, str]] | None = None,
    ) -> str:
        """`history`: turnos previos como (`user`|`assistant`, texto), del mas viejo al mas nuevo."""
        if not self.configured:
            raise AIUnavailable("Gemini no esta configurado.")
        contents = [
            {
                "role": "model" if role == "assistant" else "user",
                "parts": [{"text": text}],
            }
            for role, text in history or []
        ]
        contents.append({"role": "user", "parts": [{"text": question}]})
        payload = {
            "systemInstruction": {"parts": [{"text": system}]},
            "contents": contents,
            "generationConfig": {
                "temperature": 0.3,
                "maxOutputTokens": 700,
                # Sin "pensamiento": respuestas cortas y sin gastar tokens de mas.
                "thinkingConfig": {"thinkingBudget": 0},
            },
        }
        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                response = await client.post(
                    GEMINI_URL.format(model=self._model),
                    json=payload,
                    headers={"x-goog-api-key": self._api_key},
                )
                response.raise_for_status()
                data = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            raise AIUnavailable from exc
        try:
            parts = data["candidates"][0]["content"]["parts"]
            text = "".join(str(p.get("text", "")) for p in parts).strip()
        except (KeyError, IndexError, TypeError, AttributeError) as exc:
            raise AIUnavailable("Gemini no devolvio respuesta.") from exc
        if not text:
            raise AIUnavailable("Gemini no devolvio respuesta.")
        return text


def get_help_llm() -> HelpLLM:
    """Dependencia de FastAPI (sobreescribible en tests)."""
    return get_gemini_client()


@lru_cache
def get_gemini_client() -> GeminiClient:
    s = get_settings()
    return GeminiClient(s.gemini_api_key, s.gemini_model, s.gemini_timeout_seconds)
