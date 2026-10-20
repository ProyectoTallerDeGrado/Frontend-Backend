"""Tablas de capacitaciones y asistencia de emprendedores."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from emprendeu.db.base import Base


class Capacitacion(Base):
    __tablename__ = "capacitaciones"

    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    fecha: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    modalidad: Mapped[str | None] = mapped_column(String(40))
    tipo: Mapped[str | None] = mapped_column(String(60))
    titulo: Mapped[str] = mapped_column(String(240))
    capacitacion_id: Mapped[int] = mapped_column(
        "capacitacionesid", BigInteger, Identity(always=False), primary_key=True
    )

    participantes: Mapped[list[CapacitacionParticipante]] = relationship(
        back_populates="capacitacion"
    )


class CapacitacionParticipante(Base):
    __tablename__ = "capacitacion_participantes"
    __table_args__ = (
        UniqueConstraint(
            "capacitacionesid",
            "emprendedorid",
            name="uq_capacitacion_participantes_capacitacionesid_emprendedorid",
        ),
        Index("ix_capacitacion_participantes_capacitacionesid", "capacitacionesid"),
        Index("ix_capacitacion_participantes_emprendedorid", "emprendedorid"),
    )

    asistencia: Mapped[bool | None] = mapped_column(Boolean)
    fecha_registro: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    capacitacion_participante_id: Mapped[int] = mapped_column(
        "capacitacion_participantesid",
        BigInteger,
        Identity(always=False),
        primary_key=True,
    )
    capacitacion_id: Mapped[int] = mapped_column(
        "capacitacionesid",
        BigInteger,
        ForeignKey(
            "capacitaciones.capacitacionesid",
            ondelete="RESTRICT",
            name="fk_capacitacion_participantes_capacitacionesid",
        ),
    )
    emprendedor_id: Mapped[int] = mapped_column(
        "emprendedorid",
        BigInteger,
        ForeignKey(
            "emprendedor.emprendedorid",
            ondelete="RESTRICT",
            name="fk_capacitacion_participantes_emprendedorid",
        ),
    )

    capacitacion: Mapped[Capacitacion] = relationship(back_populates="participantes")
