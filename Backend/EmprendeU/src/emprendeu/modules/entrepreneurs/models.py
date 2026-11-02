"""Tablas del emprendedor y su pertenencia a emprendimientos."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    String,
    Text,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from emprendeu.db.base import Base


class Emprendedor(Base):
    __tablename__ = "emprendedor"
    __table_args__ = (
        UniqueConstraint("usuarioid", name="uq_emprendedor_usuarioid"),
        Index("ix_emprendedor_usuarioid", "usuarioid"),
        # Un documento de identidad no se repite entre emprendedores (sin distinguir
        # mayusculas); los vacios no cuentan. Lo valida tambien el servicio.
        Index(
            "uq_emprendedor_documento_identidad",
            func.lower(text("documento_identidad")),
            unique=True,
            postgresql_where=text(
                "documento_identidad IS NOT NULL AND documento_identidad <> ''"
            ),
        ),
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


class Postulacion(Base):
    """Solicitud de ingreso al programa (CU26).

    Al admitirla, la capa de aplicacion crea `usuario`, `emprendedor` y
    `emprendimiento` en una sola transaccion y los enlaza aqui. Una decision
    (admitida o rechazada) no se puede revertir: los CHECK lo garantizan.
    """

    __tablename__ = "postulaciones"
    __table_args__ = (
        CheckConstraint(
            "estado IN ('pendiente', 'admitida', 'rechazada')",
            name="ck_postulaciones_estado",
        ),
        CheckConstraint(
            "(estado = 'pendiente' AND fecha_decision IS NULL "
            "AND decidido_por_usuarioid IS NULL) "
            "OR (estado <> 'pendiente' AND fecha_decision IS NOT NULL "
            "AND decidido_por_usuarioid IS NOT NULL)",
            name="ck_postulaciones_decision",
        ),
        CheckConstraint(
            "(estado = 'admitida' AND emprendedorid IS NOT NULL "
            "AND emprendimientoid IS NOT NULL) "
            "OR (estado <> 'admitida' AND emprendedorid IS NULL "
            "AND emprendimientoid IS NULL)",
            name="ck_postulaciones_vinculos",
        ),
        UniqueConstraint("emprendedorid", name="uq_postulaciones_emprendedorid"),
        UniqueConstraint("emprendimientoid", name="uq_postulaciones_emprendimientoid"),
        Index(
            "uq_postulaciones_email_pendiente",
            func.lower(text("email")),
            unique=True,
            postgresql_where=text("estado = 'pendiente'"),
        ),
        Index("ix_postulaciones_decidido_por", "decidido_por_usuarioid"),
    )

    nombre: Mapped[str] = mapped_column(String(160))
    apellido: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(254))
    telefono: Mapped[str | None] = mapped_column(String(35))
    documento_identidad: Mapped[str | None] = mapped_column(String(50))
    nombre_emprendimiento: Mapped[str] = mapped_column(String(160))
    descripcion_emprendimiento: Mapped[str | None] = mapped_column(Text)
    sector: Mapped[str | None] = mapped_column(String(120))
    fecha_postulacion: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    estado: Mapped[str] = mapped_column(String(40), server_default="pendiente")
    fecha_decision: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    observaciones_decision: Mapped[str | None] = mapped_column(Text)
    postulacion_id: Mapped[int] = mapped_column(
        "postulacionesid", BigInteger, Identity(always=False), primary_key=True
    )
    decidido_por_usuario_id: Mapped[int | None] = mapped_column(
        "decidido_por_usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid",
            ondelete="RESTRICT",
            name="fk_postulaciones_decidido_por",
        ),
    )
    emprendedor_id: Mapped[int | None] = mapped_column(
        "emprendedorid",
        BigInteger,
        ForeignKey(
            "emprendedor.emprendedorid",
            ondelete="RESTRICT",
            name="fk_postulaciones_emprendedorid",
        ),
    )
    emprendimiento_id: Mapped[int | None] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_postulaciones_emprendimientoid",
        ),
    )
