"""Errores de dominio de documents."""

from emprendeu.core.errors import DomainError, NotFoundError


class DocumentNotFound(NotFoundError):
    code = "document_not_found"

    def __init__(self) -> None:
        super().__init__("Documento no encontrado.")


class FileTypeNotAllowed(DomainError):
    code = "file_type_not_allowed"
    status_code = 415

    def __init__(self, allowed: list[str]) -> None:
        super().__init__(
            "Tipo de archivo no permitido.", details={"permitidos": allowed}
        )
