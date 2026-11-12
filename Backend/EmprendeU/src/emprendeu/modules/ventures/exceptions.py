"""Errores de dominio del modulo ventures."""

from emprendeu.core.errors import ConflictError, DomainError, Forbidden, NotFoundError


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


class InvalidStageTransition(ConflictError):
    """Solo se avanza a la etapa activa inmediatamente siguiente (CU12)."""

    code = "invalid_stage_transition"

    def __init__(self, expected: str | None) -> None:
        super().__init__(
            f"Solo se puede pasar a la etapa siguiente: {expected}."
            if expected
            else "El emprendimiento ya esta en la ultima etapa.",
            details={"siguiente": expected},
        )


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


class EntrepreneurRequired(DomainError):
    code = "entrepreneur_required"
    status_code = 422

    def __init__(self) -> None:
        super().__init__("Indica el emprendedor al que pertenece el emprendimiento.")


class ReservedFields(Forbidden):
    code = "reserved_fields"

    def __init__(self, fields: list[str]) -> None:
        super().__init__(
            "Esos campos solo los cambia la coordinacion.",
            details={"campos": fields},
        )


class EntrepreneurNotFoundForVenture(DomainError):
    code = "entrepreneur_not_found"
    status_code = 422

    def __init__(self, emprendedor_id: int) -> None:
        super().__init__(
            "Ese emprendedor no existe.", details={"emprendedor_id": emprendedor_id}
        )


class DuplicateMember(DomainError):
    code = "duplicate_member"
    status_code = 422

    def __init__(self, emprendedor_id: int) -> None:
        super().__init__(
            "Un emprendedor aparece dos veces en el equipo.",
            details={"emprendedor_id": emprendedor_id},
        )


class AlreadyMember(ConflictError):
    code = "already_member"

    def __init__(self) -> None:
        super().__init__("El emprendedor ya es integrante de este emprendimiento.")


class MemberNotFound(NotFoundError):
    code = "member_not_found"

    def __init__(self) -> None:
        super().__init__("El emprendedor no es integrante de este emprendimiento.")


class LastMember(ConflictError):
    code = "last_member"

    def __init__(self) -> None:
        super().__init__("El emprendimiento debe quedar con al menos un integrante.")
