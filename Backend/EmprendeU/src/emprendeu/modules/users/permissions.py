"""Catalogo de permisos del sistema.

Cada permiso se llama `modulo:accion` y existe como fila de `permiso`
(la migracion de semilla los crea). Aqui viven los nombres validos y las
constantes que usan los routers de todos los modulos con `require_permission`.
"""

from typing import Final

MODULES: Final[tuple[str, ...]] = (
    "usuarios",
    "emprendedores",
    "asesorias",
    "seguimiento",
    "ia",
    "reportes",
    "config",
)
ACTIONS: Final[tuple[str, ...]] = (
    "consulta",
    "registro",
    "modificacion",
    "administrativo",
)


def permission_name(module: str, action: str) -> str:
    return f"{module}:{action}"


ALL_PERMISSIONS: Final[frozenset[str]] = frozenset(
    permission_name(m, a) for m in MODULES for a in ACTIONS
)

# Atajos para los routers (modulo `usuarios`).
USERS_READ: Final = permission_name("usuarios", "consulta")
USERS_CREATE: Final = permission_name("usuarios", "registro")
USERS_UPDATE: Final = permission_name("usuarios", "modificacion")
USERS_ADMIN: Final = permission_name("usuarios", "administrativo")

ADMIN_ROLE: Final = "administrador"
DEFAULT_ROLE: Final = "emprendedor"
ENABLED: Final = "habilitada"
DISABLED: Final = "deshabilitada"
