"""Errores de dominio del modulo entrepreneurs."""

from emprendeu.core.errors import NotFoundError


class EntrepreneurNotFound(NotFoundError):
    code = "entrepreneur_not_found"

    def __init__(self) -> None:
        super().__init__("Emprendedor no encontrado.")
