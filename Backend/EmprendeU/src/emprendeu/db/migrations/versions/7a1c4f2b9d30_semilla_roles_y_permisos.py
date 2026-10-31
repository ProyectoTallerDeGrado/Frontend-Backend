"""semilla de roles y permisos

Revision ID: 7a1c4f2b9d30
Revises: 5e0ae5b96cf1
Create Date: 2026-10-30 16:30:00

Inserta los cuatro roles del sistema y los 28 permisos (7 modulos x 4 acciones)
con la matriz por defecto del diseno. Los permisos se nombran `modulo:accion`.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "7a1c4f2b9d30"
down_revision: str | Sequence[str] | None = "5e0ae5b96cf1"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

ROLES = {
    "administrador": "Gestiona usuarios, roles, permisos y configuracion general.",
    "coordinador": "Supervisa emprendimientos, indicadores y alertas del CIE-U.",
    "asesor": "Registra asesorias, recomendaciones y compromisos asignados.",
    "emprendedor": "Usuario de la app movil: progreso, tareas y asistente IA.",
}

MODULES = [
    "usuarios",
    "emprendedores",
    "asesorias",
    "seguimiento",
    "ia",
    "reportes",
    "config",
]
ACTIONS = {
    "c": "consulta",
    "r": "registro",
    "m": "modificacion",
    "a": "administrativo",
}

# rol -> modulo -> letras de accion (c, r, m, a)
DEFAULTS = {
    "administrador": {
        "usuarios": "crma",
        "emprendedores": "c",
        "asesorias": "c",
        "seguimiento": "c",
        "ia": "",
        "reportes": "c",
        "config": "crma",
    },
    "coordinador": {
        "usuarios": "",
        "emprendedores": "crm",
        "asesorias": "cr",
        "seguimiento": "crm",
        "ia": "c",
        "reportes": "cr",
        "config": "cm",
    },
    "asesor": {
        "usuarios": "",
        "emprendedores": "c",
        "asesorias": "crm",
        "seguimiento": "cr",
        "ia": "",
        "reportes": "",
        "config": "",
    },
    "emprendedor": {
        "usuarios": "",
        "emprendedores": "cr",
        "asesorias": "c",
        "seguimiento": "cr",
        "ia": "cr",
        "reportes": "",
        "config": "",
    },
}


def _permission(module: str, letter: str) -> str:
    return f"{module}:{ACTIONS[letter]}"


def upgrade() -> None:
    bind = op.get_bind()
    for name, description in ROLES.items():
        bind.execute(
            sa.text("INSERT INTO cieu.rol (nombre, descripcion) VALUES (:n, :d)"),
            {"n": name, "d": description},
        )
    for module in MODULES:
        for letter in ACTIONS:
            bind.execute(
                sa.text("INSERT INTO cieu.permiso (nombre) VALUES (:n)"),
                {"n": _permission(module, letter)},
            )
    for role, modules in DEFAULTS.items():
        for module, letters in modules.items():
            for letter in letters:
                bind.execute(
                    sa.text(
                        "INSERT INTO cieu.rol_permiso (rolid, permisoid) "
                        "SELECT r.rolid, p.permisoid FROM cieu.rol r, cieu.permiso p "
                        "WHERE r.nombre = :r AND p.nombre = :p"
                    ),
                    {"r": role, "p": _permission(module, letter)},
                )


def downgrade() -> None:
    bind = op.get_bind()
    bind.execute(sa.text("DELETE FROM cieu.rol_permiso"))
    bind.execute(sa.text("DELETE FROM cieu.permiso"))
    bind.execute(sa.text("DELETE FROM cieu.rol"))
