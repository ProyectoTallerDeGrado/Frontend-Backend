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
