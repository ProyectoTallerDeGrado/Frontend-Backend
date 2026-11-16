"""Errores de dominio del modulo users."""

from emprendeu.core.errors import (
    ConflictError,
    DomainError,
    Forbidden,
    NotFoundError,
    Unauthorized,
)


class InvalidCredentials(Unauthorized):
    code = "invalid_credentials"

    def __init__(self) -> None:
        super().__init__("Correo o contrasena incorrectos.")


class AccountDisabled(Forbidden):
    code = "account_disabled"

    def __init__(self) -> None:
        super().__init__("La cuenta esta deshabilitada.")


class EmailAlreadyRegistered(ConflictError):
    code = "email_taken"

    def __init__(self) -> None:
        super().__init__("Ya existe una cuenta con ese correo.")


class InvalidFullName(DomainError):
    code = "invalid_name"
    status_code = 422

    def __init__(self) -> None:
        super().__init__("Ingresa nombre y apellido.")


class UserNotFound(NotFoundError):
    code = "user_not_found"

    def __init__(self) -> None:
        super().__init__("Usuario no encontrado.")


class RoleNotFound(NotFoundError):
    code = "role_not_found"

    def __init__(self) -> None:
        super().__init__("Rol no encontrado.")


class CannotDisableSelf(ConflictError):
    code = "cannot_disable_self"

    def __init__(self) -> None:
        super().__init__("No puedes deshabilitar tu propia cuenta.")


class InvalidPermissions(DomainError):
    code = "invalid_permissions"
    status_code = 422


class AdminLockout(ConflictError):
    code = "admin_lockout"

    def __init__(self) -> None:
        super().__init__(
            "El rol administrador debe conservar usuarios:consulta y usuarios:administrativo."
        )


class WrongCurrentPassword(DomainError):
    """400, no 401: un 401 haria que el cliente cerrara la sesion del usuario."""

    code = "wrong_password"

    def __init__(self) -> None:
        super().__init__("La contrasena actual no es correcta.")


class RoleNameTaken(ConflictError):
    code = "role_name_taken"

    def __init__(self) -> None:
        super().__init__("Ya existe un rol con ese nombre.")


class RoleInUse(ConflictError):
    code = "role_in_use"

    def __init__(self) -> None:
        super().__init__("El rol tiene usuarios asignados: reasignalos antes.")


class SystemRoleProtected(ConflictError):
    code = "system_role_protected"

    def __init__(self) -> None:
        super().__init__("Los roles del sistema no se pueden renombrar ni eliminar.")


class InvalidResetCode(DomainError):
    """El codigo no existe, vencio, ya se uso o se agotaron los intentos (400)."""

    code = "invalid_code"

    def __init__(self) -> None:
        super().__init__("El codigo no es valido o ya vencio. Pide uno nuevo.")
