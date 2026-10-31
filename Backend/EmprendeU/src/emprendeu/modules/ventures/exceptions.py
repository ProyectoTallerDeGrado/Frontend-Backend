"""Errores de dominio del modulo ventures."""

from emprendeu.core.errors import ConflictError, DomainError, NotFoundError


class VentureNotFound(NotFoundError):
    code = "venture_not_found"

    def __init__(self) -> None:
        super().__init__("Emprendimiento no encontrado.")


class StageNotFound(NotFoundError):
    code = "stage_not_found"

    def __init__(self) -> None:
        super().__init__("Etapa no encontrada.")


class StageInactive(ConflictError):
    code = "stage_inactive"

    def __init__(self) -> None:
        super().__init__("La etapa esta inactiva y no se puede asignar.")


class MilestoneNotFound(NotFoundError):
    code = "milestone_not_found"

    def __init__(self) -> None:
        super().__init__("Hito no encontrado.")


class NeedNotFound(NotFoundError):
    code = "need_not_found"

    def __init__(self) -> None:
        super().__init__("Necesidad no encontrada.")


class InvalidStageState(DomainError):
    code = "invalid_state"
    status_code = 422
