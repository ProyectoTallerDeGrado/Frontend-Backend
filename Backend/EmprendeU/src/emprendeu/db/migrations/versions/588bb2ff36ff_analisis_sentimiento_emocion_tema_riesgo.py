"""analisis sentimiento emocion tema riesgo

Revision ID: 588bb2ff36ff
Revises: 799812c8f41f
Create Date: 2026-11-15 20:57:48.721173

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "588bb2ff36ff"
down_revision: str | Sequence[str] | None = "799812c8f41f"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


# Claves validas (copiadas de `ai_assistant/sentiment.py`: una migracion no depende del codigo).
EMOTIONS = (
    "motivacion",
    "tranquilidad",
    "neutral",
    "preocupacion",
    "estres",
    "frustracion",
    "desanimo",
)
TOPICS = (
    "finanzas",
    "ventas_clientes",
    "equipo",
    "tiempo_estudios",
    "producto",
    "tramites",
    "personal",
    "otro",
)
TABLE = "analisis_sentimiento"
# La pantalla de Bienestar exige `ia:consulta`: hasta ahora solo lo tenia coordinacion.
NEW_READERS = ("administrador", "asesor")


def _in(values: tuple[str, ...]) -> str:
    return ", ".join(f"'{v}'" for v in values)


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column(
        TABLE, sa.Column("emocion", sa.String(length=20), nullable=True), schema="cieu"
    )
    op.add_column(
        TABLE, sa.Column("tema", sa.String(length=30), nullable=True), schema="cieu"
    )
    op.add_column(
        TABLE,
        sa.Column(
            "riesgo", sa.Boolean(), server_default=sa.text("false"), nullable=False
        ),
        schema="cieu",
    )
    op.add_column(
        TABLE,
        sa.Column(
            "origen", sa.String(length=10), server_default="servidor", nullable=False
        ),
        schema="cieu",
    )
    op.add_column(
        TABLE,
        sa.Column(
            "metodo", sa.String(length=10), server_default="lexico", nullable=False
        ),
        schema="cieu",
    )
    op.add_column(
        TABLE,
        sa.Column("referencia_cliente", sa.String(length=64), nullable=True),
        schema="cieu",
    )
    op.create_unique_constraint(
        "uq_analisis_sentimiento_emprendedor_referencia",
        TABLE,
        ["emprendedorid", "referencia_cliente"],
        schema="cieu",
    )
    # Alembic no genera los CHECK: van a mano, con el mismo nombre que en el modelo.
    op.create_check_constraint(
        "ck_analisis_sentimiento_emocion",
        TABLE,
        f"emocion IS NULL OR emocion IN ({_in(EMOTIONS)})",
        schema="cieu",
    )
    op.create_check_constraint(
        "ck_analisis_sentimiento_tema",
        TABLE,
        f"tema IS NULL OR tema IN ({_in(TOPICS)})",
        schema="cieu",
    )
    op.create_check_constraint(
        "ck_analisis_sentimiento_origen",
        TABLE,
        "origen IN ('servidor', 'local')",
        schema="cieu",
    )
    op.create_check_constraint(
        "ck_analisis_sentimiento_metodo",
        TABLE,
        "metodo IN ('lexico', 'modelo')",
        schema="cieu",
    )
    for role in NEW_READERS:
        op.execute(
            sa.text(
                "INSERT INTO cieu.rol_permiso (rolid, permisoid) "
                "SELECT r.rolid, p.permisoid FROM cieu.rol r, cieu.permiso p "
                "WHERE r.nombre = :r AND p.nombre = 'ia:consulta' "
                "AND NOT EXISTS (SELECT 1 FROM cieu.rol_permiso x "
                "WHERE x.rolid = r.rolid AND x.permisoid = p.permisoid)"
            ).bindparams(r=role)
        )


def downgrade() -> None:
    """Downgrade schema."""
    for role in NEW_READERS:
        op.execute(
            sa.text(
                "DELETE FROM cieu.rol_permiso WHERE rolid = "
                "(SELECT rolid FROM cieu.rol WHERE nombre = :r) AND permisoid = "
                "(SELECT permisoid FROM cieu.permiso WHERE nombre = 'ia:consulta')"
            ).bindparams(r=role)
        )
    for name in ("metodo", "origen", "tema", "emocion"):
        op.drop_constraint(
            f"ck_analisis_sentimiento_{name}", TABLE, schema="cieu", type_="check"
        )
    op.drop_constraint(
        "uq_analisis_sentimiento_emprendedor_referencia",
        TABLE,
        schema="cieu",
        type_="unique",
    )
    for column in (
        "referencia_cliente",
        "metodo",
        "origen",
        "riesgo",
        "tema",
        "emocion",
    ):
        op.drop_column(TABLE, column, schema="cieu")
