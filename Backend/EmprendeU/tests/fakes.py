"""Dobles de prueba."""

from emprendeu.modules.ai_assistant.exceptions import AIUnavailable
from emprendeu.modules.ai_assistant.models import EMBEDDING_DIM

KEYWORDS = ("costos", "ventas", "marketing", "modelo")


class FakeLLM:
    """Embeddings por conteo de palabras clave (rellenados a `EMBEDDING_DIM`)."""

    def __init__(self) -> None:
        self.down = False
        self.last_system = ""
        self.last_history: list[tuple[str, str]] = []
        self.chat_calls = 0
        self.embed_calls = 0

    async def embed(self, texts: list[str]) -> list[list[float]]:
        self.embed_calls += 1
        if self.down:
            raise AIUnavailable
        pad = [0.0] * (EMBEDDING_DIM - len(KEYWORDS))
        return [[float(t.lower().count(k)) for k in KEYWORDS] + pad for t in texts]

    async def chat(
        self,
        system: str,
        question: str,
        history: list[tuple[str, str]] | None = None,
    ) -> str:
        self.chat_calls += 1
        if self.down:
            raise AIUnavailable
        self.last_system = system
        self.last_history = list(history or [])
        return "Respuesta del coach basada en el contexto."

    async def ping(self) -> bool:
        return not self.down
