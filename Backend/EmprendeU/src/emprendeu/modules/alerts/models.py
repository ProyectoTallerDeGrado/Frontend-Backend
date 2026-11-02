"""Tablas de alertas sobre emprendimientos y su catalogo de tipos."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
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
        Index("ix_alertas_atendida_por", "atendida_por_usuarioid"),
    )

    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_generacion: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    prioridad: Mapped[str | None] = mapped_column(String(30))
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

    # Quien la dejo atendida (CU13); `revisada` y `descartada` no lo fijan.
    atendida_por_usuario_id: Mapped[int | None] = mapped_column(
        "atendida_por_usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid", ondelete="RESTRICT", name="fk_alertas_atendida_por"
        ),
    )

    tipo_alerta: Mapped[TipoAlerta] = relationship(back_populates="alertas")


class ParametroSeguimiento(Base):
    """Parametro de deteccion de inactividad y riesgo, en formato clave-valor.

    Las claves conocidas estan en `alerts/repository.py` (`SETTING_KEYS`).
    """

    __tablename__ = "parametros_seguimiento"
    __table_args__ = (
        UniqueConstraint("clave", name="uq_parametros_seguimiento_clave"),
    )

    clave: Mapped[str] = mapped_column(String(80))
    valor: Mapped[str] = mapped_column(String(255))
    descripcion: Mapped[str | None] = mapped_column(Text)
    fecha_actualizacion: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    parametro_seguimiento_id: Mapped[int] = mapped_column(
        "parametrosseguimientoid",
        BigInteger,
        Identity(always=False),
        primary_key=True,
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
