"""Errores de dominio de alerts."""

from emprendeu.core.errors import ConflictError, Forbidden, NotFoundError


class AlertNotFound(NotFoundError):
    code = "alert_not_found"

    def __init__(self) -> None:
        super().__init__("Alerta no encontrada.")


class AlertClosed(ConflictError):
    code = "alert_closed"

    def __init__(self) -> None:
        super().__init__("La alerta ya esta cerrada y no se reabre.")


class AlertNotAssigned(Forbidden):
    code = "alert_not_assigned"

    def __init__(self) -> None:
        super().__init__("Esa alerta es de un emprendimiento que no tienes asignado.")
