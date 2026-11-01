"""Errores de dominio de gamification."""

from emprendeu.core.errors import ConflictError, DomainError, NotFoundError


class ChallengeNotFound(NotFoundError):
    code = "challenge_not_found"

    def __init__(self) -> None:
        super().__init__("Reto no encontrado.")


class BadgeNotFound(NotFoundError):
    code = "badge_not_found"

    def __init__(self) -> None:
        super().__init__("Insignia no encontrada.")


class ChallengeLocked(ConflictError):
    code = "challenge_locked"

    def __init__(self) -> None:
        super().__init__("Completa el reto anterior para desbloquearlo.")


class ChallengeAlreadyCompleted(ConflictError):
    code = "challenge_completed"

    def __init__(self) -> None:
        super().__init__("Este reto ya fue cumplido; el XP se otorga una sola vez.")


class NoVenture(ConflictError):
    code = "no_venture"

    def __init__(self) -> None:
        super().__init__("Primero registra tu emprendimiento.")


class InvalidStage(DomainError):
    code = "invalid_stage"
    status_code = 422

    def __init__(self) -> None:
        super().__init__("La etapa indicada no existe.")
