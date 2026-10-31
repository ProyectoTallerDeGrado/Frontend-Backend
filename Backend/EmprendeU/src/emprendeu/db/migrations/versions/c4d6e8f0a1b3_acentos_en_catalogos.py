"""acentos en los catalogos sembrados

Revision ID: c4d6e8f0a1b3
Revises: b3c5d7e9f1a2
Create Date: 2026-10-31 12:00:00

Las semillas anteriores se escribieron sin tildes. Esos textos se muestran tal
cual en la web y el movil, asi que se corrigen aqui. Es solo datos: no cambia
el esquema. Las claves tecnicas (nombres de rol y de permiso) siguen sin tildes.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "c4d6e8f0a1b3"
down_revision: str | Sequence[str] | None = "b3c5d7e9f1a2"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

ETAPAS = {
    "Preincubacion": ("Preincubación", "Validación inicial de la idea y del problema."),
    "Incubacion": ("Incubación", "Construcción y prueba del prototipo con clientes."),
    "Crecimiento": ("Crecimiento", "Escalamiento, finanzas y consolidación de ventas."),
    "Graduacion": ("Graduación", "Cierre del programa y salida del acompañamiento."),
}

# orden -> (titulo, descripcion)
RETOS = {
    1: (
        "Completar el perfil del emprendimiento",
        "Registra los datos básicos de tu emprendimiento.",
    ),
    2: (
        "Definir la propuesta de valor",
        "Describe en una frase qué problema resuelves y para quién.",
    ),
    3: (
        "Entrevistar a 5 clientes potenciales",
        "Conversa con clientes reales y registra lo que aprendiste de cada conversación.",
    ),
    4: (
        "Construir un prototipo mínimo",
        "Crea la versión más simple de tu producto o servicio para ponerla a prueba con clientes.",
    ),
    5: (
        "Registrar ventas de prueba",
        "Realiza tus primeras ventas y anota los resultados y aprendizajes.",
    ),
    6: (
        "Presentar el plan financiero",
        "Estructura costos, precios y punto de equilibrio con apoyo de un mentor.",
    ),
}

INSIGNIAS = {
    "Primer paso": ("Primer paso", "Completa tu primer reto."),
    "Constancia": ("Constancia", "Accede a la app 7 días seguidos."),
    "Validador": ("Validador", "Completa las entrevistas con clientes."),
    "Bitacora al dia": (
        "Bitácora al día",
        "Registra avances cada semana durante un mes.",
    ),
    "Conector": ("Conector", "Asiste a tu primera mentoría."),
    "Graduado": ("Graduado", "Completa todas las etapas del programa."),
}

TIPOS_SESION = {
    "Mentoria": ("Mentoría", "Sesión de mentoría con un asesor."),
    "Asesoria": ("Asesoría", "Sesión de asesoría puntual."),
}

ROLES = {
    "administrador": "Gestiona usuarios, roles, permisos y configuración general.",
    "coordinador": "Supervisa emprendimientos, indicadores y alertas del CIE-U.",
    "asesor": "Registra asesorías, recomendaciones y compromisos asignados.",
    "emprendedor": "Usuario de la app móvil: progreso, tareas y asistente IA.",
}


def upgrade() -> None:
    bind = op.get_bind()
    for old, (name, description) in ETAPAS.items():
        bind.execute(
            sa.text(
                "UPDATE cieu.etapas SET nombre = :n, descripcion = :d WHERE nombre = :o"
            ),
            {"n": name, "d": description, "o": old},
        )
    for order, (title, description) in RETOS.items():
        bind.execute(
            sa.text(
                "UPDATE cieu.retos SET titulo = :t, descripcion = :d WHERE orden = :o"
            ),
            {"t": title, "d": description, "o": order},
        )
    for old, (name, criterion) in INSIGNIAS.items():
        bind.execute(
            sa.text(
                "UPDATE cieu.insignias SET nombre = :n, criterio = :c WHERE nombre = :o"
            ),
            {"n": name, "c": criterion, "o": old},
        )
    for old, (name, description) in TIPOS_SESION.items():
        bind.execute(
            sa.text(
                "UPDATE cieu.tipo SET nombre = :n, descripcion = :d WHERE nombre = :o"
            ),
            {"n": name, "d": description, "o": old},
        )
    for name, description in ROLES.items():
        bind.execute(
            sa.text("UPDATE cieu.rol SET descripcion = :d WHERE nombre = :n"),
            {"n": name, "d": description},
        )


def downgrade() -> None:
    """Solo corrige textos: no se revierte (volver a quitar las tildes no aporta nada)."""
