"""Tabla de bitacora: auditoria de cambios por usuario."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    String,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from emprendeu.db.base import Base


class Bitacora(Base):
    __tablename__ = "bitacora"
    __table_args__ = (Index("ix_bitacora_usuarioid", "usuarioid"),)

    accion: Mapped[str | None] = mapped_column(String(120))
    datos_anteriores: Mapped[dict | None] = mapped_column(JSONB)
    datos_nuevos: Mapped[dict | None] = mapped_column(JSONB)
    fecha: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ip: Mapped[str | None] = mapped_column(String(45))
    tabla: Mapped[str | None] = mapped_column(String(120))
    bitacora_id: Mapped[int] = mapped_column(
        "bitacoraid", BigInteger, Identity(always=False), primary_key=True
    )
    usuario_id: Mapped[int | None] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid", ondelete="RESTRICT", name="fk_bitacora_usuarioid"
        ),
    )
    id_registro: Mapped[str | None] = mapped_column(String(250))
