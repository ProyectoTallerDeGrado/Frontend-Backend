"""Tablas del emprendimiento: etapas del proceso, hitos y necesidades."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from emprendeu.db.base import Base


class Emprendimiento(Base):
    __tablename__ = "emprendimiento"

    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_actualizacion: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    fecha_creacion: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    fecha_inicio: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    nombre: Mapped[str] = mapped_column(String(160))
    sector: Mapped[str | None] = mapped_column(String(120))
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid", BigInteger, Identity(always=False), primary_key=True
    )

    etapas: Mapped[list[EmprendimientoEtapa]] = relationship(
        back_populates="emprendimiento"
    )
    hitos: Mapped[list[Hito]] = relationship(back_populates="emprendimiento")
    necesidades: Mapped[list[EmprendimientoNecesidad]] = relationship(
        back_populates="emprendimiento"
    )


class Etapa(Base):
    __tablename__ = "etapas"
    __table_args__ = (UniqueConstraint("orden", name="uq_etapas_orden"),)

    criterios: Mapped[str | None] = mapped_column(Text)
    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    nombre: Mapped[str] = mapped_column(String(160))
    orden: Mapped[int | None] = mapped_column(Integer)
    etapa_id: Mapped[int] = mapped_column(
        "etapasid", BigInteger, Identity(always=False), primary_key=True
    )

    emprendimientos: Mapped[list[EmprendimientoEtapa]] = relationship(
        back_populates="etapa"
    )


class EmprendimientoEtapa(Base):
    __tablename__ = "emprendimiento_etapas"
    __table_args__ = (
        CheckConstraint(
            "fecha_fin IS NULL OR fecha_inicio IS NULL OR fecha_fin >= fecha_inicio",
            name="ck_emprendimiento_etapas_fechas",
        ),
        # Como maximo una etapa activa por emprendimiento.
        Index(
            "uq_emprendimiento_etapa_activa",
            "emprendimientoid",
            unique=True,
            postgresql_where=text("lower(estado) = 'activa'"),
        ),
        Index("ix_emprendimiento_etapas_etapasid", "etapasid"),
        Index("ix_emprendimiento_etapas_emprendimientoid", "emprendimientoid"),
    )

    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_fin: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    fecha_inicio: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    observaciones: Mapped[str | None] = mapped_column(Text)
    emprendimiento_etapa_id: Mapped[int] = mapped_column(
        "emprendimiento_etapasid", BigInteger, Identity(always=False), primary_key=True
    )
    etapa_id: Mapped[int] = mapped_column(
        "etapasid",
        BigInteger,
        ForeignKey(
            "etapas.etapasid",
            ondelete="RESTRICT",
            name="fk_emprendimiento_etapas_etapasid",
        ),
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_emprendimiento_etapas_emprendimientoid",
        ),
    )

    etapa: Mapped[Etapa] = relationship(back_populates="emprendimientos")
    emprendimiento: Mapped[Emprendimiento] = relationship(back_populates="etapas")
    hitos: Mapped[list[Hito]] = relationship(back_populates="emprendimiento_etapa")


class Hito(Base):
    __tablename__ = "hito"
    __table_args__ = (
        Index("ix_hito_emprendimientoid", "emprendimientoid"),
        Index("ix_hito_emprendimiento_etapasid", "emprendimiento_etapasid"),
    )

    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_cumplimiento: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    fecha_estimada: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    titulo: Mapped[str] = mapped_column(String(240))
    hito_id: Mapped[int] = mapped_column(
        "hitoid", BigInteger, Identity(always=False), primary_key=True
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_hito_emprendimientoid",
        ),
    )
    emprendimiento_etapa_id: Mapped[int | None] = mapped_column(
        "emprendimiento_etapasid",
        BigInteger,
        ForeignKey(
            "emprendimiento_etapas.emprendimiento_etapasid",
            ondelete="RESTRICT",
            name="fk_hito_emprendimiento_etapasid",
        ),
    )

    emprendimiento: Mapped[Emprendimiento] = relationship(back_populates="hitos")
    emprendimiento_etapa: Mapped[EmprendimientoEtapa | None] = relationship(
        back_populates="hitos"
    )


class Necesidad(Base):
    __tablename__ = "necesidades"

    descripcion: Mapped[str | None] = mapped_column(Text)
    nombre: Mapped[str] = mapped_column(String(160))
    necesidad_id: Mapped[int] = mapped_column(
        "necesidadesid", BigInteger, Identity(always=False), primary_key=True
    )

    emprendimientos: Mapped[list[EmprendimientoNecesidad]] = relationship(
        back_populates="necesidad"
    )


class EmprendimientoNecesidad(Base):
    __tablename__ = "emprendimiento_necesidades"
    __table_args__ = (
        UniqueConstraint(
            "emprendimientoid",
            "necesidadesid",
            name="uq_emprendimiento_necesidades_emprendimientoid_necesidadesid",
        ),
        CheckConstraint(
            "fecha_resuelta IS NULL OR fecha_detectada IS NULL "
            "OR fecha_resuelta >= fecha_detectada",
            name="ck_necesidades_fechas",
        ),
        Index("ix_emprendimiento_necesidades_emprendimientoid", "emprendimientoid"),
        Index("ix_emprendimiento_necesidades_necesidadesid", "necesidadesid"),
    )

    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_detectada: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    fecha_resuelta: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    prioridad: Mapped[str | None] = mapped_column(String(30))
    emprendimiento_necesidad_id: Mapped[int] = mapped_column(
        "emprendimiento_necesidadesid",
        BigInteger,
        Identity(always=False),
        primary_key=True,
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_emprendimiento_necesidades_emprendimientoid",
        ),
    )
    necesidad_id: Mapped[int] = mapped_column(
        "necesidadesid",
        BigInteger,
        ForeignKey(
            "necesidades.necesidadesid",
            ondelete="RESTRICT",
            name="fk_emprendimiento_necesidades_necesidadesid",
        ),
    )

    emprendimiento: Mapped[Emprendimiento] = relationship(back_populates="necesidades")
    necesidad: Mapped[Necesidad] = relationship(back_populates="emprendimientos")
