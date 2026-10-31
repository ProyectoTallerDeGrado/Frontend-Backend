"""usuario: ultimo acceso, estado con CHECK y valor por defecto

Revision ID: 5e0ae5b96cf1
Revises: cfed9e8e2430
Create Date: 2026-10-30 16:14:01.797906

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "5e0ae5b96cf1"
down_revision: str | Sequence[str] | None = "cfed9e8e2430"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column(
        "usuario",
        sa.Column("ultimo_acceso", sa.DateTime(timezone=True), nullable=True),
        schema="cieu",
    )
    # Alembic no detecta estos dos cambios: se escriben a mano.
    op.alter_column("usuario", "estado", server_default="habilitada", schema="cieu")
    op.create_check_constraint(
        "ck_usuario_estado",
        "usuario",
        "estado IN ('habilitada', 'deshabilitada')",
        schema="cieu",
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint("ck_usuario_estado", "usuario", schema="cieu", type_="check")
    op.alter_column("usuario", "estado", server_default=None, schema="cieu")
    op.drop_column("usuario", "ultimo_acceso", schema="cieu")
