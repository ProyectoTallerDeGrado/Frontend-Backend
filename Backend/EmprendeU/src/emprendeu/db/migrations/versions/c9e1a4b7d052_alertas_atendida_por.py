"""alertas.atendida_por_usuarioid

Fase 3 (CU13): hasta ahora no se sabia quien dejo atendida cada alerta. Las filas
existentes quedan en NULL.

Revision ID: c9e1a4b7d052
Revises: b7d2e5a91c34
Create Date: 2026-11-02 10:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "c9e1a4b7d052"
down_revision: str | Sequence[str] | None = "b7d2e5a91c34"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

S = "cieu"


def upgrade() -> None:
    op.add_column(
        "alertas",
        sa.Column("atendida_por_usuarioid", sa.BigInteger(), nullable=True),
        schema=S,
    )
    op.create_foreign_key(
        "fk_alertas_atendida_por",
        "alertas",
        "usuario",
        ["atendida_por_usuarioid"],
        ["usuarioid"],
        source_schema=S,
        referent_schema=S,
        ondelete="RESTRICT",
    )
    op.create_index(
        "ix_alertas_atendida_por", "alertas", ["atendida_por_usuarioid"], schema=S
    )


def downgrade() -> None:
    op.drop_index("ix_alertas_atendida_por", table_name="alertas", schema=S)
    op.drop_constraint(
        "fk_alertas_atendida_por", "alertas", schema=S, type_="foreignkey"
    )
    op.drop_column("alertas", "atendida_por_usuarioid", schema=S)
