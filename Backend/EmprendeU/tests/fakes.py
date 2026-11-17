"""Dobles de prueba."""

from emprendeu.modules.ai_assistant.exceptions import AIUnavailable
from emprendeu.modules.ai_assistant.models import EMBEDDING_DIM
from emprendeu.modules.ai_assistant.sentiment import CLASSIFY_PROMPT

KEYWORDS = ("costos", "ventas", "marketing", "modelo")


class FakeLLM:
    """Embeddings por conteo de palabras clave (rellenados a `EMBEDDING_DIM`)."""

    def __init__(self) -> None:
        self.down = False
        self.last_system = ""
        self.last_history: list[tuple[str, str]] = []
        self.chat_calls = 0
        self.embed_calls = 0
        self.classify_calls = 0
        self.classify_down = False
        # Lo que "responde el modelo" al clasificar el animo de un mensaje.
        self.classify_reply = "no es json"

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
        if system == CLASSIFY_PROMPT:
            # Clasificacion de animo: no cuenta como respuesta del coach.
            self.classify_calls += 1
            if self.down or self.classify_down:
                raise AIUnavailable
            return self.classify_reply
        self.chat_calls += 1
        if self.down:
            raise AIUnavailable
        self.last_system = system
        self.last_history = list(history or [])
        return "Respuesta del coach basada en el contexto."

    async def ping(self) -> bool:
        return not self.down


class FakeMailer:
    """Guarda los correos en memoria; `down` simula un SMTP caido."""

    def __init__(self) -> None:
        self.sent: list[tuple[str, str, str]] = []
        self.down = False

    async def send(self, to: str, subject: str, body: str) -> None:
        from emprendeu.core.mailer import EmailUnavailable

        if self.down:
            raise EmailUnavailable
        self.sent.append((to, subject, body))

    def last_code(self) -> str:
        import re

        match = re.search(r"\b(\d{6})\b", self.sent[-1][2])
        assert match
        return match.group(1)


class FakeHelpLLM:
    """Doble de Gemini para el asistente de ayuda."""

    def __init__(self) -> None:
        self.configured = True
        self.down = False
        self.calls = 0
        self.last_system = ""
        self.last_history: list[tuple[str, str]] = []

    async def chat(
        self,
        system: str,
        question: str,
        history: list[tuple[str, str]] | None = None,
    ) -> str:
        self.calls += 1
        if self.down:
            raise AIUnavailable
        self.last_system = system
        self.last_history = list(history or [])
        return "Respuesta de ayuda generada por la IA."


class FakePushDispatcher:
    """Guarda los push que se habrian enviado (tras cada commit)."""

    def __init__(self) -> None:
        self.messages: list = []

    async def deliver(self, messages: list) -> None:
        self.messages.extend(messages)

    def to(self, usuario_id: int) -> list:
        return [m for m in self.messages if usuario_id in m.user_ids]
