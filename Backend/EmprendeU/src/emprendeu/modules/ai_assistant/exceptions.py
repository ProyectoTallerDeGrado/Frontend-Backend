"""Errores de dominio de ai_assistant."""

from emprendeu.core.errors import DomainError, Forbidden, NotFoundError


class AIUnavailable(DomainError):
    code = "ai_unavailable"
    status_code = 503

    def __init__(self, detail: str = "El asistente no esta disponible.") -> None:
        super().__init__(detail)


class ConversationNotFound(NotFoundError):
    code = "conversation_not_found"

    def __init__(self) -> None:
        super().__init__("Conversacion no encontrada.")


class KnowledgeNotFound(NotFoundError):
    code = "knowledge_not_found"

    def __init__(self) -> None:
        super().__init__("Documento de conocimiento no encontrado.")


class NotEntrepreneur(Forbidden):
    code = "not_entrepreneur"

    def __init__(self) -> None:
        super().__init__("Solo los emprendedores pueden usar el coach.")


class EmptyKnowledge(DomainError):
    code = "empty_knowledge"
    status_code = 422

    def __init__(self) -> None:
        super().__init__("El documento no contiene texto util.")
