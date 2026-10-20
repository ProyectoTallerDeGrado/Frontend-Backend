"""Tablas de indicadores de impacto y sus valores por periodo."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    BigInteger,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from emprendeu.db.base import Base


class TipoIndicador(Base):
    __tablename__ = "tipos_indicadores"

    descripcion: Mapped[str | None] = mapped_column(Text)
    nombre: Mapped[str] = mapped_column(String(160))
    tipo: Mapped[str | None] = mapped_column(String(60))
    unidad: Mapped[str | None] = mapped_column(String(50))
    tipo_indicador_id: Mapped[int] = mapped_column(
        "tipos_indicadoresid", BigInteger, Identity(always=False), primary_key=True
    )

    valores: Mapped[list[ValorIndicador]] = relationship(
        back_populates="tipo_indicador"
    )


class ValorIndicador(Base):
    __tablename__ = "valores_indicadores"
    __table_args__ = (
        Index("ix_valores_indicadores_emprendimientoid", "emprendimientoid"),
        Index("ix_valores_indicadores_tipos_indicadoresid", "tipos_indicadoresid"),
    )

    fecha_registro: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    periodo: Mapped[str | None] = mapped_column(String(40))
    valor: Mapped[Decimal | None] = mapped_column(Numeric(18, 4))
    valor_indicador_id: Mapped[int] = mapped_column(
        "valores_indicadoresid", BigInteger, Identity(always=False), primary_key=True
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_valores_indicadores_emprendimientoid",
        ),
    )
    tipo_indicador_id: Mapped[int] = mapped_column(
        "tipos_indicadoresid",
        BigInteger,
        ForeignKey(
            "tipos_indicadores.tipos_indicadoresid",
            ondelete="RESTRICT",
            name="fk_valores_indicadores_tipos_indicadoresid",
        ),
    )

    tipo_indicador: Mapped[TipoIndicador] = relationship(back_populates="valores")
