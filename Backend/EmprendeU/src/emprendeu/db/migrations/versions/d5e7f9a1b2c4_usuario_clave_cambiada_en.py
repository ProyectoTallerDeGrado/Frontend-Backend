"""usuario: clave_cambiada_en para invalidar tokens al cambiar la contrasena

Revision ID: d5e7f9a1b2c4
Revises: c4d6e8f0a1b3
Create Date: 2026-11-01 12:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "d5e7f9a1b2c4"
down_revision: str | Sequence[str] | None = "c4d6e8f0a1b3"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column(
        "usuario",
        sa.Column("clave_cambiada_en", sa.DateTime(timezone=True), nullable=True),
        schema="cieu",
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column("usuario", "clave_cambiada_en", schema="cieu")
