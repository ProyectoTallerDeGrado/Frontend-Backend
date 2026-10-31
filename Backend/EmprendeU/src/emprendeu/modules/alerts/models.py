"""Tablas de alertas sobre emprendimientos y su catalogo de tipos."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    Integer,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from emprendeu.db.base import Base


class TipoAlerta(Base):
    """Catalogo de tipos de alerta (tabla `tipos`).

    El nombre de la clase se desmarca de la tabla para no colisionar con
    `mentoring.Tipo` (tabla `tipo`), que es otro catalogo distinto.
    """

    __tablename__ = "tipos"

    nombre: Mapped[str] = mapped_column(String(160))
    tipo_alerta_id: Mapped[int] = mapped_column(
        "tiposid", BigInteger, Identity(always=False), primary_key=True
    )

    alertas: Mapped[list[Alerta]] = relationship(back_populates="tipo_alerta")


class Alerta(Base):
    __tablename__ = "alertas"
    __table_args__ = (
        Index("ix_alertas_emprendimientoid", "emprendimientoid"),
        Index("ix_alertas_tiposid", "tiposid"),
    )

    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_generacion: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    prioridad: Mapped[str | None] = mapped_column(String(30))
    tipo: Mapped[str | None] = mapped_column(String(60))
    titulo: Mapped[str] = mapped_column(String(240))
    alerta_id: Mapped[int] = mapped_column(
        "alertasid", BigInteger, Identity(always=False), primary_key=True
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_alertas_emprendimientoid",
        ),
    )
    tipo_alerta_id: Mapped[int] = mapped_column(
        "tiposid",
        BigInteger,
        ForeignKey("tipos.tiposid", ondelete="RESTRICT", name="fk_alertas_tiposid"),
    )

    tipo_alerta: Mapped[TipoAlerta] = relationship(back_populates="alertas")


class ParametroSeguimiento(Base):
    """Configuracion unica de deteccion de inactividad y riesgo (fila id = 1)."""

    __tablename__ = "parametros_seguimiento"
    __table_args__ = (
        CheckConstraint(
            "inactividad_dias BETWEEN 1 AND 365", name="ck_param_inactividad"
        ),
        CheckConstraint(
            "caida_sentimiento_pct BETWEEN 1 AND 100", name="ck_param_caida"
        ),
        CheckConstraint(
            "periodos_consecutivos BETWEEN 1 AND 12", name="ck_param_periodos"
        ),
    )

    alertar_incumplimiento: Mapped[bool] = mapped_column(Boolean, default=False)
    caida_sentimiento_pct: Mapped[int] = mapped_column(Integer, default=25)
    fecha_actualizacion: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    inactividad_dias: Mapped[int] = mapped_column(Integer, default=14)
    notificar_asesor: Mapped[bool] = mapped_column(Boolean, default=True)
    notificar_coordinador: Mapped[bool] = mapped_column(Boolean, default=True)
    periodos_consecutivos: Mapped[int] = mapped_column(Integer, default=2)
    parametro_seguimiento_id: Mapped[int] = mapped_column(
        "parametros_seguimientoid", BigInteger, primary_key=True
    )
    usuario_id: Mapped[int | None] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid",
            ondelete="RESTRICT",
            name="fk_parametros_seguimiento_usuarioid",
        ),
    )
