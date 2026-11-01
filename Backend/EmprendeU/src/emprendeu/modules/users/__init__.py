"""Modulo users: identidad y acceso (usuario, rol, permiso).

API publica del modulo. Otros modulos solo importan desde aqui.
"""

from emprendeu.modules.users.dependencies import (
    CurrentUserDep,
    build_user_service,
    get_current_user,
    require_permission,
    require_staff_permission,
)
from emprendeu.modules.users.models import (
    Permiso,
    Rol,
    RolPermiso,
    RolUsuario,
    Usuario,
)
from emprendeu.modules.users.router import router
from emprendeu.modules.users.service import CurrentUser, UserService

__all__ = [
    "CurrentUser",
    "CurrentUserDep",
    "Permiso",
    "Rol",
    "RolPermiso",
    "RolUsuario",
    "UserService",
    "Usuario",
    "build_user_service",
    "get_current_user",
    "require_permission",
    "require_staff_permission",
    "router",
]
