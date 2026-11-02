"""fragmentos_documento: nombre de la restriccion unica igual al esquema de referencia

Revision ID: a6d9c1e3f527
Revises: f4b8d2e6a913
Create Date: 2026-11-03 10:00:00.000000

Solo cambia el nombre: PostgreSQL habia truncado el original a 63 caracteres y el esquema de
referencia (`cieu_schema_completo.sql`) usa `uq_fragmentos_docconoc_numero`. La definicion
(`UNIQUE (documentos_conocimientoid, numero_fragmento)`) es la misma; no se toca ningun dato.
"""

from collections.abc import Sequence

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "a6d9c1e3f527"
down_revision: str | Sequence[str] | None = "f4b8d2e6a913"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

OLD = "uq_fragmentos_documento_documentos_conocimientoid_numero_fragme"
NEW = "uq_fragmentos_docconoc_numero"


def upgrade() -> None:
    """Upgrade schema."""
    op.execute(
        f"ALTER TABLE cieu.fragmentos_documento RENAME CONSTRAINT {OLD} TO {NEW}"
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.execute(
        f"ALTER TABLE cieu.fragmentos_documento RENAME CONSTRAINT {NEW} TO {OLD}"
    )
