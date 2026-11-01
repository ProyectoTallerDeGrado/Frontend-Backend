"""Dobles de prueba."""

from emprendeu.modules.ai_assistant.exceptions import AIUnavailable

KEYWORDS = ("costos", "ventas", "marketing", "modelo")


class FakeLLM:
    """Embeddings por conteo de palabras clave; chat devuelve un texto fijo."""

    def __init__(self) -> None:
        self.down = False
        self.last_system = ""

    async def embed(self, texts: list[str]) -> list[list[float]]:
        if self.down:
            raise AIUnavailable
        return [[float(t.lower().count(k)) for k in KEYWORDS] for t in texts]

    async def chat(self, system: str, question: str) -> str:
        if self.down:
            raise AIUnavailable
        self.last_system = system
        return "Respuesta del coach basada en el contexto."

    async def ping(self) -> bool:
        return not self.down
