"""Errores de dominio de alerts."""

from emprendeu.core.errors import NotFoundError


class AlertNotFound(NotFoundError):
    code = "alert_not_found"

    def __init__(self) -> None:
        super().__init__("Alerta no encontrada.")
