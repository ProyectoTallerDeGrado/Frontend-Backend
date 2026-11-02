"""Errores de dominio de indicators."""

from emprendeu.core.errors import DomainError, NotFoundError


class IndicatorTypeNotFound(NotFoundError):
    code = "indicator_type_not_found"

    def __init__(self) -> None:
        super().__init__("Tipo de indicador no encontrado.")


class InvalidPeriod(DomainError):
    code = "invalid_period"
    status_code = 422

    def __init__(self) -> None:
        super().__init__("La fecha final debe ser igual o posterior a la inicial.")
