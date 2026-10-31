"""Errores de dominio de indicators."""

from emprendeu.core.errors import NotFoundError


class IndicatorTypeNotFound(NotFoundError):
    code = "indicator_type_not_found"

    def __init__(self) -> None:
        super().__init__("Tipo de indicador no encontrado.")
