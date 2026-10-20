"""Tabla de documentos subidos por usuarios."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    String,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from emprendeu.db.base import Base


class Documento(Base):
    __tablename__ = "documentos"
    __table_args__ = (
        Index("ix_documentos_usuarioid", "usuarioid"),
        Index("ix_documentos_emprendimientoid", "emprendimientoid"),
    )

    fecha_subida: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    nombre: Mapped[str] = mapped_column(String(160))
    ruta: Mapped[str | None] = mapped_column(String(1000))
    tipo: Mapped[str | None] = mapped_column(String(60))
    documento_id: Mapped[int] = mapped_column(
        "documentosid", BigInteger, Identity(always=False), primary_key=True
    )
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid", ondelete="RESTRICT", name="fk_documentos_usuarioid"
        ),
    )
    emprendimiento_id: Mapped[int | None] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_documentos_emprendimientoid",
        ),
    )
