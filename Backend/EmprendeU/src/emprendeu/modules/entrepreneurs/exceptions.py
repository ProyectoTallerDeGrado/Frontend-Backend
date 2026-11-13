"""Errores de dominio del modulo entrepreneurs."""

from emprendeu.core.errors import ConflictError, DomainError, NotFoundError


class EntrepreneurNotFound(NotFoundError):
    code = "entrepreneur_not_found"

    def __init__(self) -> None:
        super().__init__("Emprendedor no encontrado.")


class DocumentAlreadyRegistered(ConflictError):
    code = "document_already_registered"

    def __init__(self) -> None:
        super().__init__("Ya existe un emprendedor con ese documento de identidad.")


class AdmissionNotFound(NotFoundError):
    code = "admission_not_found"

    def __init__(self) -> None:
        super().__init__("Postulacion no encontrada.")


class AdmissionDecided(ConflictError):
    """Una decision de admitir o rechazar es definitiva (CU26)."""

    code = "decision_final"

    def __init__(self) -> None:
        super().__init__("La postulacion ya tiene una decision definitiva.")


class AdmissionIncomplete(DomainError):
    """Faltan datos para evaluar o admitir la postulacion."""

    code = "admission_incomplete"
    status_code = 422

    def __init__(self, missing: list[str]) -> None:
        super().__init__(
            "Faltan datos para admitir la postulacion.", details={"faltan": missing}
        )


class ApplicationPending(ConflictError):
    code = "application_pending"

    def __init__(self) -> None:
        super().__init__("Ya hay una postulacion pendiente con ese correo.")
