"""semilla de catalogos: etapas, retos, insignias, tipos y parametros

Revision ID: b3c5d7e9f1a2
Revises: a82f0b6251fa
Create Date: 2026-10-31 10:00:00

Datos del diseno: 4 etapas, 6 retos con su XP, 6 insignias, tipos de sesion,
tipos de alerta, tipos de indicador y los parametros de seguimiento por defecto.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "b3c5d7e9f1a2"
down_revision: str | Sequence[str] | None = "a82f0b6251fa"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

ETAPAS = [
    (1, "Preincubacion", "Validacion inicial de la idea y del problema."),
    (2, "Incubacion", "Construccion y prueba del prototipo con clientes."),
    (3, "Crecimiento", "Escalamiento, finanzas y consolidacion de ventas."),
    (4, "Graduacion", "Cierre del programa y salida del acompanamiento."),
]

# (orden, titulo, etapa, xp, tipo, descripcion)
RETOS = [
    (
        1,
        "Completar el perfil del emprendimiento",
        "Preincubacion",
        50,
        "perfil",
        "Registra los datos basicos de tu emprendimiento.",
    ),
    (
        2,
        "Definir la propuesta de valor",
        "Preincubacion",
        100,
        "propuesta",
        "Describe en una frase que problema resuelves y para quien.",
    ),
    (
        3,
        "Entrevistar a 5 clientes potenciales",
        "Preincubacion",
        120,
        "validacion",
        "Conversa con clientes reales y registra lo que aprendiste de cada conversacion.",
    ),
    (
        4,
        "Construir un prototipo minimo",
        "Incubacion",
        150,
        "prototipo",
        "Crea la version mas simple de tu producto o servicio para ponerla a prueba con clientes.",
    ),
    (
        5,
        "Registrar ventas de prueba",
        "Incubacion",
        200,
        "ventas",
        "Realiza tus primeras ventas y anota los resultados y aprendizajes.",
    ),
    (
        6,
        "Presentar el plan financiero",
        "Crecimiento",
        250,
        "finanzas",
        "Estructura costos, precios y punto de equilibrio con apoyo de un mentor.",
    ),
]

# (nombre, criterio, xp)
INSIGNIAS = [
    ("Primer paso", "Completa tu primer reto.", 25),
    ("Constancia", "Accede a la app 7 dias seguidos.", 40),
    ("Validador", "Completa las entrevistas con clientes.", 80),
    ("Bitacora al dia", "Registra avances cada semana durante un mes.", 60),
    ("Conector", "Asiste a tu primera mentoria.", 50),
    ("Graduado", "Completa todas las etapas del programa.", 300),
]


def upgrade() -> None:
    bind = op.get_bind()
    for orden, nombre, descripcion in ETAPAS:
        bind.execute(
            sa.text(
                "INSERT INTO cieu.etapas (nombre, descripcion, orden, estado) "
                "VALUES (:n, :d, :o, 'activa')"
            ),
            {"n": nombre, "d": descripcion, "o": orden},
        )
    for orden, titulo, etapa, xp, tipo, descripcion in RETOS:
        bind.execute(
            sa.text(
                "INSERT INTO cieu.retos "
                "(titulo, descripcion, tipo, xp_recompensa, estado, orden, etapasid) "
                "SELECT :t, :d, :tipo, :xp, 'activo', :o, etapasid "
                "FROM cieu.etapas WHERE nombre = :e"
            ),
            {
                "t": titulo,
                "d": descripcion,
                "tipo": tipo,
                "xp": xp,
                "o": orden,
                "e": etapa,
            },
        )
    for nombre, criterio, xp in INSIGNIAS:
        bind.execute(
            sa.text(
                "INSERT INTO cieu.insignias (nombre, criterio, xp_recompensa, estado) "
                "VALUES (:n, :c, :xp, 'activa')"
            ),
            {"n": nombre, "c": criterio, "xp": xp},
        )
    for nombre, descripcion in [
        ("Mentoria", "Sesion de mentoria con un asesor."),
        ("Asesoria", "Sesion de asesoria puntual."),
    ]:
        bind.execute(
            sa.text("INSERT INTO cieu.tipo (nombre, descripcion) VALUES (:n, :d)"),
            {"n": nombre, "d": descripcion},
        )
    for nombre in ("inactividad", "sentimiento", "compromiso_vencido"):
        bind.execute(
            sa.text("INSERT INTO cieu.tipos (nombre) VALUES (:n)"), {"n": nombre}
        )
    for nombre, unidad in [
        ("Ventas mensuales", "Bs"),
        ("Clientes activos", "clientes"),
        ("Empleos generados", "empleos"),
    ]:
        bind.execute(
            sa.text(
                "INSERT INTO cieu.tipos_indicadores (nombre, tipo, unidad) "
                "VALUES (:n, 'cuantitativo', :u)"
            ),
            {"n": nombre, "u": unidad},
        )
    bind.execute(
        sa.text(
            "INSERT INTO cieu.parametros_seguimiento "
            "(parametros_seguimientoid, inactividad_dias, caida_sentimiento_pct, "
            "periodos_consecutivos, notificar_coordinador, notificar_asesor, "
            "alertar_incumplimiento) VALUES (1, 14, 25, 2, true, true, false)"
        )
    )


def downgrade() -> None:
    bind = op.get_bind()
    for table in (
        "parametros_seguimiento",
        "tipos_indicadores",
        "tipos",
        "tipo",
        "insignias",
        "retos",
        "etapas",
    ):
        bind.execute(sa.text(f"DELETE FROM cieu.{table}"))
