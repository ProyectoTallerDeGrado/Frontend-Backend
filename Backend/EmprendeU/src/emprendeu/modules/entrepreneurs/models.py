"""Tablas del emprendedor y su pertenencia a emprendimientos."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from emprendeu.db.base import Base


class Emprendedor(Base):
    __tablename__ = "emprendedor"
    __table_args__ = (
        UniqueConstraint("usuarioid", name="uq_emprendedor_usuarioid"),
        Index("ix_emprendedor_usuarioid", "usuarioid"),
    )

    documento_identidad: Mapped[str | None] = mapped_column(String(50))
    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_registro: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    emprendedor_id: Mapped[int] = mapped_column(
        "emprendedorid", BigInteger, Identity(always=False), primary_key=True
    )
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid", ondelete="RESTRICT", name="fk_emprendedor_usuarioid"
        ),
    )

    emprendimientos: Mapped[list[EmprendimientoEmprendedor]] = relationship(
        back_populates="emprendedor"
    )


class EmprendimientoEmprendedor(Base):
    __tablename__ = "emprendimiento_emprendedores"
    __table_args__ = (
        UniqueConstraint(
            "emprendedorid",
            "emprendimientoid",
            name="uq_emprendimiento_emprendedores_emprendedorid_emprendimientoid",
        ),
        Index("ix_emprendimiento_emprendedores_emprendedorid", "emprendedorid"),
        Index("ix_emprendimiento_emprendedores_emprendimientoid", "emprendimientoid"),
    )

    fecha_ingreso: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    rol_en_emprendimiento: Mapped[str | None] = mapped_column(String(100))
    emprendimiento_emprendedor_id: Mapped[int] = mapped_column(
        "emprendimiento_emprendedoresid",
        BigInteger,
        Identity(always=False),
        primary_key=True,
    )
    emprendedor_id: Mapped[int] = mapped_column(
        "emprendedorid",
        BigInteger,
        ForeignKey(
            "emprendedor.emprendedorid",
            ondelete="RESTRICT",
            name="fk_emprendimiento_emprendedores_emprendedorid",
        ),
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_emprendimiento_emprendedores_emprendimientoid",
        ),
    )

    emprendedor: Mapped[Emprendedor] = relationship(back_populates="emprendimientos")
