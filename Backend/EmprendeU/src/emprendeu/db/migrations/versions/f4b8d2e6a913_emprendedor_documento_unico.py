"""emprendedor: documento de identidad unico

Revision ID: f4b8d2e6a913
Revises: e2a7c4d96b18
Create Date: 2026-11-03 09:00:00.000000

El servicio ya rechazaba un documento repetido, pero dos altas simultaneas podian
colarlo. El indice lo garantiza en la base (sin distinguir mayusculas; los vacios no
cuentan). Si ya hay documentos repetidos la migracion se detiene con el detalle, para
que se resuelvan a mano: no se borra ni se cambia ningun dato.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "f4b8d2e6a913"
down_revision: str | Sequence[str] | None = "e2a7c4d96b18"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""
    duplicated = (
        op.get_bind()
        .execute(
            sa.text(
                "SELECT lower(documento_identidad) AS doc, count(*) AS total, "
                "array_agg(emprendedorid ORDER BY emprendedorid) AS ids "
                "FROM cieu.emprendedor "
                "WHERE documento_identidad IS NOT NULL AND documento_identidad <> '' "
                "GROUP BY lower(documento_identidad) HAVING count(*) > 1"
            )
        )
        .all()
    )
    if duplicated:
        detail = "; ".join(
            f"{r.doc!r} en emprendedores {list(r.ids)}" for r in duplicated
        )
        raise RuntimeError(
            "No se puede crear el indice unico: hay documentos de identidad repetidos "
            f"({detail}). Corrigelos y vuelve a correr la migracion."
        )
    op.create_index(
        "uq_emprendedor_documento_identidad",
        "emprendedor",
        [sa.text("lower(documento_identidad)")],
        unique=True,
        schema="cieu",
        postgresql_where=sa.text(
            "documento_identidad IS NOT NULL AND documento_identidad <> ''"
        ),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(
        "uq_emprendedor_documento_identidad",
        table_name="emprendedor",
        schema="cieu",
    )
