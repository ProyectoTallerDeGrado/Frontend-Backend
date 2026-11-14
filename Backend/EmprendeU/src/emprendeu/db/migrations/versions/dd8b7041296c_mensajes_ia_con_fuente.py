"""mensajes_ia con_fuente

Revision ID: dd8b7041296c
Revises: 5342749a900e
Create Date: 2026-11-14 18:11:34.333337

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "dd8b7041296c"
down_revision: str | Sequence[str] | None = "5342749a900e"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

# Texto fijo que el coach responde cuando no encuentra documentos (service.FALLBACK).
# Se copia aquí: una migración no debe depender del código, que puede cambiar.
FALLBACK = (
    "No encontré información suficiente en la base documental del CIE-U "
    "para responder con certeza."
)


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column(
        "mensajes_ia",
        sa.Column("con_fuente", sa.Boolean(), nullable=True),
        schema="cieu",
    )
    # Respuestas ya guardadas: sin fuente si son el texto de «no encontré información».
    op.execute(
        sa.text(
            "UPDATE cieu.mensajes_ia SET con_fuente = (contenido <> :fallback) "
            "WHERE tipo = 'asistente'"
        ).bindparams(fallback=FALLBACK)
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column("mensajes_ia", "con_fuente", schema="cieu")
