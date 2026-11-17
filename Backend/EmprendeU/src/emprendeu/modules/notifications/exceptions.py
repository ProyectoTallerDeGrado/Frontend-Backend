"""Errores de dominio de notifications."""

from emprendeu.core.errors import NotFoundError


class NotificationNotFound(NotFoundError):
    code = "notification_not_found"

    def __init__(self) -> None:
        super().__init__("Notificacion no encontrada.")
