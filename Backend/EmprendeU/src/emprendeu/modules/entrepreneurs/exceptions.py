"""Errores de dominio del modulo entrepreneurs."""

from emprendeu.core.errors import ConflictError, NotFoundError


class EntrepreneurNotFound(NotFoundError):
    code = "entrepreneur_not_found"

    def __init__(self) -> None:
        super().__init__("Emprendedor no encontrado.")


class DocumentAlreadyRegistered(ConflictError):
    code = "document_already_registered"

    def __init__(self) -> None:
        super().__init__("Ya existe un emprendedor con ese documento de identidad.")


class ApplicationNotFound(NotFoundError):
    code = "application_not_found"

    def __init__(self) -> None:
        super().__init__("Postulacion no encontrada.")


class ApplicationDecided(ConflictError):
    code = "application_decided"

    def __init__(self) -> None:
        super().__init__("La postulacion ya fue decidida y no se puede cambiar.")


class ApplicationPending(ConflictError):
    code = "application_pending"

    def __init__(self) -> None:
        super().__init__("Ya hay una postulacion pendiente con ese correo.")
