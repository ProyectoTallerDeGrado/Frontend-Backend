"""usuario.password_changed_at

Fase 1 del plan de finalizacion: al cambiar la contrasena se guarda el instante y
el backend rechaza los tokens emitidos antes. Las filas existentes quedan en NULL
(ningun token se invalida).

Revision ID: b7d2e5a91c34
Revises: f33df1970606
Create Date: 2026-11-01 18:30:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "b7d2e5a91c34"
down_revision: str | Sequence[str] | None = "f33df1970606"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "usuario",
        sa.Column("password_changed_at", sa.DateTime(timezone=True), nullable=True),
        schema="cieu",
    )


def downgrade() -> None:
    op.drop_column("usuario", "password_changed_at", schema="cieu")
