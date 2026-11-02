"""Errores de dominio de training."""

from emprendeu.core.errors import ConflictError, DomainError, NotFoundError


class TrainingNotFound(NotFoundError):
    code = "training_not_found"

    def __init__(self) -> None:
        super().__init__("Capacitacion no encontrada.")


class ParticipantNotFound(NotFoundError):
    code = "participant_not_found"

    def __init__(self) -> None:
        super().__init__("Participante no encontrado.")


class AlreadyEnrolled(ConflictError):
    code = "already_enrolled"

    def __init__(self) -> None:
        super().__init__("Ya estas inscrito en esta capacitacion.")


class TrainingClosed(ConflictError):
    code = "training_closed"

    def __init__(self) -> None:
        super().__init__("La capacitacion ya termino o fue cancelada y no se edita.")


class InvalidTrainingTransition(ConflictError):
    code = "invalid_training_transition"

    def __init__(self, current: str | None, target: str) -> None:
        super().__init__(
            f"No se puede pasar de {current} a {target}.",
            details={"actual": current, "destino": target},
        )


class TrainingNotOpen(ConflictError):
    code = "training_not_open"

    def __init__(self) -> None:
        super().__init__("La capacitacion no esta publicada.")


class DateRequired(DomainError):
    code = "date_required"
    status_code = 422

    def __init__(self) -> None:
        super().__init__("Una capacitacion necesita fecha para publicarse.")
