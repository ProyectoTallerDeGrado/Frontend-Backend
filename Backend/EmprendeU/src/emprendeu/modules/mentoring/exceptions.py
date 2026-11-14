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


class AvailabilityOverlap(ConflictError):
    code = "availability_overlap"

    def __init__(self) -> None:
        super().__init__("Los horarios se solapan; no se guardo ninguno.")


class AvailabilityNotFound(NotFoundError):
    code = "availability_not_found"

    def __init__(self) -> None:
        super().__init__("Horario no encontrado.")


class MentorNotEnabled(ConflictError):
    code = "mentor_not_enabled"

    def __init__(self) -> None:
        super().__init__("El asesor no esta habilitado.")


class AssignmentExists(ConflictError):
    code = "assignment_exists"

    def __init__(self) -> None:
        super().__init__(
            "Ese asesor ya tiene una asignacion activa en el emprendimiento."
        )


class NotAssigned(Forbidden):
    code = "not_assigned"

    def __init__(self) -> None:
        super().__init__("No estas asignado a este emprendimiento.")


class MentorNotAssigned(Forbidden):
    code = "mentor_not_assigned"

    def __init__(self) -> None:
        super().__init__("Ese asesor no esta asignado a tu emprendimiento.")


class SessionMismatch(DomainError):
    code = "session_mismatch"
    status_code = 422

    def __init__(self) -> None:
        super().__init__("La sesion no es de ese emprendimiento.")


class ResponsibleNotMember(DomainError):
    code = "responsible_not_member"
    status_code = 422

    def __init__(self) -> None:
        super().__init__(
            "El responsable debe ser un emprendedor del emprendimiento "
            "o un asesor asignado."
        )


class FutureDate(DomainError):
    code = "future_date"
    status_code = 422

    def __init__(self) -> None:
        super().__init__("La fecha realizada no puede estar en el futuro.")


class SessionNotEditable(ConflictError):
    code = "session_closed"

    def __init__(self) -> None:
        super().__init__("La sesion ya no admite cambios.")


class NoVenture(ConflictError):
    code = "no_venture"

    def __init__(self) -> None:
        super().__init__("Primero registra tu emprendimiento.")


class SessionConflict(ConflictError):
    code = "session_conflict"

    def __init__(self) -> None:
        super().__init__(
            "Ese horario tiene una mentoría programada; cancélala antes de modificarlo."
        )


class SessionDuplicate(ConflictError):
    code = "session_duplicate"

    def __init__(self) -> None:
        super().__init__("Ya existe una sesión de este emprendimiento en ese horario.")
