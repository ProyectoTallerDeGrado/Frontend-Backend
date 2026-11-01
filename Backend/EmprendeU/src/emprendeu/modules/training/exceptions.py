"""Errores de dominio de training."""

from emprendeu.core.errors import ConflictError, NotFoundError


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
