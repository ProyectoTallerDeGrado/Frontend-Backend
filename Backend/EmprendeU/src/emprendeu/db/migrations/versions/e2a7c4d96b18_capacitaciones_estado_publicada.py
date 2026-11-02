"""capacitaciones: estado publicada (antes programada)

Revision ID: e2a7c4d96b18
Revises: c9e1a4b7d052
Create Date: 2026-11-02 18:00:00.000000

Cambio solo de datos: una capacitacion ya cargada como `programada` estaba a la vista
de todos, que es lo que ahora significa `publicada`. Los estados pasan a ser
borrador, publicada, realizada y cancelada. No se borra ni se altera el esquema.
"""

from collections.abc import Sequence

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "e2a7c4d96b18"
down_revision: str | Sequence[str] | None = "c9e1a4b7d052"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""
    op.execute(
        "UPDATE cieu.capacitaciones SET estado = 'publicada' WHERE estado = 'programada'"
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.execute(
        "UPDATE cieu.capacitaciones SET estado = 'programada' "
        "WHERE estado IN ('publicada', 'borrador')"
    )
