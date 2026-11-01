"""Tablas de gamificacion: insignias, retos y movimientos de XP."""

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
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from emprendeu.db.base import Base


class Insignia(Base):
    __tablename__ = "insignias"
    __table_args__ = (
        # CHECK a nivel de tabla: Alembic no renderiza los constraints de columna.
        CheckConstraint("xp_recompensa >= 0", name="insignias_xp_recompensa_check"),
    )

    criterio: Mapped[str | None] = mapped_column(Text)
    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    icono: Mapped[str | None] = mapped_column(String(300))
    nombre: Mapped[str] = mapped_column(String(160))
    xp_recompensa: Mapped[int | None] = mapped_column(Integer)
    insignia_id: Mapped[int] = mapped_column(
        "insigniasid", BigInteger, Identity(always=False), primary_key=True
    )

    emprendedores: Mapped[list[EmprendedorInsignia]] = relationship(
        back_populates="insignia"
    )


class EmprendedorInsignia(Base):
    __tablename__ = "emprendedor_insignias"
    __table_args__ = (
        UniqueConstraint(
            "emprendedorid",
            "insigniasid",
            name="uq_emprendedor_insignias_emprendedorid_insigniasid",
        ),
        Index("ix_emprendedor_insignias_insigniasid", "insigniasid"),
        Index("ix_emprendedor_insignias_emprendedorid", "emprendedorid"),
    )

    fecha_obtenida: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    emprendedor_insignia_id: Mapped[int] = mapped_column(
        "emprendedor_insigniasid", BigInteger, Identity(always=False), primary_key=True
    )
    insignia_id: Mapped[int] = mapped_column(
        "insigniasid",
        BigInteger,
        ForeignKey(
            "insignias.insigniasid",
            ondelete="RESTRICT",
            name="fk_emprendedor_insignias_insigniasid",
        ),
    )
    emprendedor_id: Mapped[int] = mapped_column(
        "emprendedorid",
        BigInteger,
        ForeignKey(
            "emprendedor.emprendedorid",
            ondelete="RESTRICT",
            name="fk_emprendedor_insignias_emprendedorid",
        ),
    )

    insignia: Mapped[Insignia] = relationship(back_populates="emprendedores")


class Reto(Base):
    __tablename__ = "retos"
    __table_args__ = (
        # CHECK a nivel de tabla: Alembic no renderiza los constraints de columna.
        CheckConstraint("xp_recompensa >= 0", name="retos_xp_recompensa_check"),
        Index("ix_retos_etapasid", "etapasid"),
    )

    criterio_completado: Mapped[str | None] = mapped_column(Text)
    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    tipo: Mapped[str | None] = mapped_column(String(60))
    titulo: Mapped[str] = mapped_column(String(240))
    xp_recompensa: Mapped[int | None] = mapped_column(Integer)
    reto_id: Mapped[int] = mapped_column(
        "retosid", BigInteger, Identity(always=False), primary_key=True
    )
    etapa_id: Mapped[int] = mapped_column(
        "etapasid",
        BigInteger,
        ForeignKey("etapas.etapasid", ondelete="RESTRICT", name="fk_retos_etapasid"),
    )
    # Orden global del camino (fase 4). Define el desbloqueo secuencial.
    orden: Mapped[int | None] = mapped_column(Integer)

    emprendimientos: Mapped[list[EmprendimientoReto]] = relationship(
        back_populates="reto"
    )
    movimientos_xp: Mapped[list[MovimientoXp]] = relationship(back_populates="reto")


class EmprendimientoReto(Base):
    __tablename__ = "emprendimiento_retos"
    __table_args__ = (
        UniqueConstraint(
            "emprendimientoid",
            "retosid",
            name="uq_emprendimiento_retos_emprendimientoid_retosid",
        ),
        CheckConstraint(
            "fecha_completado IS NULL OR fecha_asignacion IS NULL "
            "OR fecha_completado >= fecha_asignacion",
            name="ck_retos_fechas",
        ),
        Index("ix_emprendimiento_retos_retosid", "retosid"),
        Index("ix_emprendimiento_retos_emprendimientoid", "emprendimientoid"),
    )

    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_asignacion: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    fecha_completado: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    emprendimiento_reto_id: Mapped[int] = mapped_column(
        "emprendimiento_retosid", BigInteger, Identity(always=False), primary_key=True
    )
    reto_id: Mapped[int] = mapped_column(
        "retosid",
        BigInteger,
        ForeignKey(
            "retos.retosid",
            ondelete="RESTRICT",
            name="fk_emprendimiento_retos_retosid",
        ),
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_emprendimiento_retos_emprendimientoid",
        ),
    )

    reto: Mapped[Reto] = relationship(back_populates="emprendimientos")


class MovimientoXp(Base):
    __tablename__ = "movimientos_xp"
    __table_args__ = (
        # CHECK a nivel de tabla: Alembic no renderiza los constraints de columna.
        CheckConstraint("cantidad >= 0", name="movimientos_xp_cantidad_check"),
        Index("ix_movimientos_xp_emprendedorid", "emprendedorid"),
        Index("ix_movimientos_xp_retosid", "retosid"),
    )

    cantidad: Mapped[int | None] = mapped_column(Integer)
    fecha: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    motivo: Mapped[str | None] = mapped_column(String(250))
    movimiento_xp_id: Mapped[int] = mapped_column(
        "movimientos_xpid", BigInteger, Identity(always=False), primary_key=True
    )
    emprendedor_id: Mapped[int] = mapped_column(
        "emprendedorid",
        BigInteger,
        ForeignKey(
            "emprendedor.emprendedorid",
            ondelete="RESTRICT",
            name="fk_movimientos_xp_emprendedorid",
        ),
    )
    reto_id: Mapped[int | None] = mapped_column(
        "retosid",
        BigInteger,
        ForeignKey(
            "retos.retosid", ondelete="RESTRICT", name="fk_movimientos_xp_retosid"
        ),
    )

    reto: Mapped[Reto | None] = relationship(back_populates="movimientos_xp")
