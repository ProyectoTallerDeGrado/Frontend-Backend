"""Tablas del asistente de IA: conversaciones, mensajes, analisis de
sentimiento y base de conocimiento fragmentada."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from emprendeu.db.base import Base


class ConversacionIa(Base):
    __tablename__ = "conversaciones_ia"
    __table_args__ = (
        CheckConstraint(
            "fecha_fin IS NULL OR fecha_inicio IS NULL OR fecha_fin >= fecha_inicio",
            name="ck_conversaciones_ia_fechas",
        ),
        Index("ix_conversaciones_ia_emprendedorid", "emprendedorid"),
        Index("ix_conversaciones_ia_emprendimientoid", "emprendimientoid"),
    )

    fecha_fin: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    fecha_inicio: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    conversacion_ia_id: Mapped[int] = mapped_column(
        "conversaciones_iaid", BigInteger, Identity(always=False), primary_key=True
    )
    emprendedor_id: Mapped[int] = mapped_column(
        "emprendedorid",
        BigInteger,
        ForeignKey(
            "emprendedor.emprendedorid",
            ondelete="RESTRICT",
            name="fk_conversaciones_ia_emprendedorid",
        ),
    )
    emprendimiento_id: Mapped[int | None] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_conversaciones_ia_emprendimientoid",
        ),
    )

    mensajes: Mapped[list[MensajeIa]] = relationship(back_populates="conversacion")


class MensajeIa(Base):
    __tablename__ = "mensajes_ia"
    __table_args__ = (
        Index("ix_mensajes_ia_conversaciones_iaid", "conversaciones_iaid"),
    )

    contenido: Mapped[str] = mapped_column(Text)
    fecha: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    tipo: Mapped[str | None] = mapped_column(String(60))
    mensaje_ia_id: Mapped[int] = mapped_column(
        "mensajes_iaid", BigInteger, Identity(always=False), primary_key=True
    )
    conversacion_ia_id: Mapped[int] = mapped_column(
        "conversaciones_iaid",
        BigInteger,
        ForeignKey(
            "conversaciones_ia.conversaciones_iaid",
            ondelete="RESTRICT",
            name="fk_mensajes_ia_conversaciones_iaid",
        ),
    )

    conversacion: Mapped[ConversacionIa] = relationship(back_populates="mensajes")
    analisis: Mapped[AnalisisSentimiento | None] = relationship(
        back_populates="mensaje"
    )


class AnalisisSentimiento(Base):
    __tablename__ = "analisis_sentimiento"
    __table_args__ = (
        # CHECK a nivel de tabla: Alembic no renderiza los constraints de columna.
        CheckConstraint(
            "indice BETWEEN -1 AND 1", name="analisis_sentimiento_indice_check"
        ),
        UniqueConstraint("mensajes_iaid", name="uq_analisis_sentimiento_mensajes_iaid"),
        Index("ix_analisis_sentimiento_emprendedorid", "emprendedorid"),
        Index("ix_analisis_sentimiento_mensajes_iaid", "mensajes_iaid"),
    )

    fecha: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    indice: Mapped[Decimal | None] = mapped_column(Numeric(6, 5))
    analisis_sentimiento_id: Mapped[int] = mapped_column(
        "analisis_sentimientoid", BigInteger, Identity(always=False), primary_key=True
    )
    emprendedor_id: Mapped[int] = mapped_column(
        "emprendedorid",
        BigInteger,
        ForeignKey(
            "emprendedor.emprendedorid",
            ondelete="RESTRICT",
            name="fk_analisis_sentimiento_emprendedorid",
        ),
    )
    mensaje_ia_id: Mapped[int | None] = mapped_column(
        "mensajes_iaid",
        BigInteger,
        ForeignKey(
            "mensajes_ia.mensajes_iaid",
            ondelete="RESTRICT",
            name="fk_analisis_sentimiento_mensajes_iaid",
        ),
    )

    mensaje: Mapped[MensajeIa | None] = relationship(back_populates="analisis")


class DocumentoConocimiento(Base):
    __tablename__ = "documentos_conocimiento"

    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_carga: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    fuente: Mapped[str | None] = mapped_column(String(300))
    ruta: Mapped[str | None] = mapped_column(String(1000))
    titulo: Mapped[str] = mapped_column(String(240))
    documento_conocimiento_id: Mapped[int] = mapped_column(
        "documentos_conocimientoid",
        BigInteger,
        Identity(always=False),
        primary_key=True,
    )

    fragmentos: Mapped[list[FragmentoDocumento]] = relationship(
        back_populates="documento"
    )


class FragmentoDocumento(Base):
    __tablename__ = "fragmentos_documento"
    __table_args__ = (
        # CHECK a nivel de tabla: Alembic no renderiza los constraints de columna.
        CheckConstraint(
            "numero_fragmento >= 0", name="fragmentos_documento_numero_fragmento_check"
        ),
        UniqueConstraint(
            "documentos_conocimientoid",
            "numero_fragmento",
            # PostgreSQL trunca los identificadores a 63 caracteres: este es el
            # nombre real que quedo en la base al cargar el SQL de referencia.
            name="uq_fragmentos_documento_documentos_conocimientoid_numero_fragme",
        ),
        Index(
            "ix_fragmentos_documento_documentos_conocimientoid",
            "documentos_conocimientoid",
        ),
    )

    contenido: Mapped[str] = mapped_column(Text)
    embedding: Mapped[dict | None] = mapped_column(JSONB)
    numero_fragmento: Mapped[int | None] = mapped_column(Integer)
    fragmento_documento_id: Mapped[int] = mapped_column(
        "fragmentos_documentoid", BigInteger, Identity(always=False), primary_key=True
    )
    documento_conocimiento_id: Mapped[int] = mapped_column(
        "documentos_conocimientoid",
        BigInteger,
        ForeignKey(
            "documentos_conocimiento.documentos_conocimientoid",
            ondelete="RESTRICT",
            name="fk_fragmentos_documento_documentos_conocimientoid",
        ),
    )

    documento: Mapped[DocumentoConocimiento] = relationship(back_populates="fragmentos")
