"""Errores de dominio de mentoring."""

from emprendeu.core.errors import ConflictError, DomainError, Forbidden, NotFoundError


class MentorNotFound(NotFoundError):
    code = "mentor_not_found"

    def __init__(self) -> None:
        super().__init__("Mentor no encontrado.")


class SessionNotFound(NotFoundError):
    code = "session_not_found"

    def __init__(self) -> None:
        super().__init__("Sesion no encontrada.")


class CommitmentNotFound(NotFoundError):
    code = "commitment_not_found"

    def __init__(self) -> None:
        super().__init__("Compromiso no encontrado.")


class AssignmentNotFound(NotFoundError):
    code = "assignment_not_found"

    def __init__(self) -> None:
        super().__init__("Asignacion no encontrada.")


class BookingNotEnabled(Forbidden):
    code = "booking_not_enabled"


class MentorLocked(Forbidden):
    code = "mentor_locked"


class SlotUnavailable(ConflictError):
    code = "slot_unavailable"

    def __init__(self) -> None:
        super().__init__("Ese horario ya no esta disponible.")


class InvalidSlot(DomainError):
    code = "invalid_slot"
    status_code = 422

    def __init__(self) -> None:
        super().__init__("El horario no corresponde a la disponibilidad del mentor.")


class SessionNotEditable(ConflictError):
    code = "session_closed"

    def __init__(self) -> None:
        super().__init__("La sesion ya no admite cambios.")


class NoVenture(ConflictError):
    code = "no_venture"

    def __init__(self) -> None:
        super().__init__("Primero registra tu emprendimiento.")
