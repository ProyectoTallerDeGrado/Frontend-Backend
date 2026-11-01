"""Tablas del acompanamiento: sesiones, participantes, compromisos,
seguimientos, recomendaciones y asignaciones de acompanantes."""

from __future__ import annotations

from datetime import datetime, time
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
    Time,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from emprendeu.db.base import Base


class Tipo(Base):
    """Catalogo de tipos de sesion de acompanamiento.

    Tabla distinta de `tipos` (catalogo de tipos de alerta, en el modulo alerts).
    """

    __tablename__ = "tipo"

    descripcion: Mapped[str | None] = mapped_column(Text)
    nombre: Mapped[str] = mapped_column(String(160))
    tipo_id: Mapped[int] = mapped_column(
        "tipoid", BigInteger, Identity(always=False), primary_key=True
    )

    sesiones: Mapped[list[SesionAcompanamiento]] = relationship(
        back_populates="tipo_catalogo"
    )


class SesionAcompanamiento(Base):
    __tablename__ = "sesiones_acompanamiento"
    __table_args__ = (
        Index("ix_sesiones_acompanamiento_emprendimientoid", "emprendimientoid"),
        Index("ix_sesiones_acompanamiento_tipoid", "tipoid"),
    )

    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_programada: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    fecha_realizada: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    modalidad: Mapped[str | None] = mapped_column(String(40))
    observaciones: Mapped[str | None] = mapped_column(Text)
    tema: Mapped[str | None] = mapped_column(String(250))
    tipo: Mapped[str | None] = mapped_column(String(60))
    sesion_acompanamiento_id: Mapped[int] = mapped_column(
        "sesiones_acompanamientoid",
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
            name="fk_sesiones_acompanamiento_emprendimientoid",
        ),
    )
    tipo_id: Mapped[int] = mapped_column(
        "tipoid",
        BigInteger,
        ForeignKey(
            "tipo.tipoid",
            ondelete="RESTRICT",
            name="fk_sesiones_acompanamiento_tipoid",
        ),
    )

    tipo_catalogo: Mapped[Tipo] = relationship(back_populates="sesiones")
    participantes: Mapped[list[SesionParticipante]] = relationship(
        back_populates="sesion"
    )
    compromisos: Mapped[list[Compromiso]] = relationship(back_populates="sesion")
    recomendaciones: Mapped[list[Recomendacion]] = relationship(back_populates="sesion")


class SesionParticipante(Base):
    __tablename__ = "sesion_participantes"
    __table_args__ = (
        UniqueConstraint(
            "sesiones_acompanamientoid",
            "usuarioid",
            name="uq_sesion_participantes_sesiones_acompanamientoid_usuarioid",
        ),
        Index("ix_sesion_participantes_usuarioid", "usuarioid"),
        Index(
            "ix_sesion_participantes_sesiones_acompanamientoid",
            "sesiones_acompanamientoid",
        ),
    )

    rol_participante: Mapped[str | None] = mapped_column(String(100))
    sesion_participante_id: Mapped[int] = mapped_column(
        "sesion_participantesid", BigInteger, Identity(always=False), primary_key=True
    )
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid",
            ondelete="RESTRICT",
            name="fk_sesion_participantes_usuarioid",
        ),
    )
    sesion_acompanamiento_id: Mapped[int] = mapped_column(
        "sesiones_acompanamientoid",
        BigInteger,
        ForeignKey(
            "sesiones_acompanamiento.sesiones_acompanamientoid",
            ondelete="RESTRICT",
            name="fk_sesion_participantes_sesiones_acompanamientoid",
        ),
    )

    sesion: Mapped[SesionAcompanamiento] = relationship(back_populates="participantes")


class Compromiso(Base):
    __tablename__ = "compromisos"
    __table_args__ = (
        Index("ix_compromisos_usuarioid", "usuarioid"),
        Index("ix_compromisos_sesiones_acompanamientoid", "sesiones_acompanamientoid"),
    )

    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_completado: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    fecha_limite: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    responsable_usuario: Mapped[str | None] = mapped_column(String(250))
    compromiso_id: Mapped[int] = mapped_column(
        "compromisosid", BigInteger, Identity(always=False), primary_key=True
    )
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid", ondelete="RESTRICT", name="fk_compromisos_usuarioid"
        ),
    )
    sesion_acompanamiento_id: Mapped[int] = mapped_column(
        "sesiones_acompanamientoid",
        BigInteger,
        ForeignKey(
            "sesiones_acompanamiento.sesiones_acompanamientoid",
            ondelete="RESTRICT",
            name="fk_compromisos_sesiones_acompanamientoid",
        ),
    )

    sesion: Mapped[SesionAcompanamiento] = relationship(back_populates="compromisos")


class Seguimiento(Base):
    __tablename__ = "seguimientos"
    __table_args__ = (
        # CHECK a nivel de tabla: Alembic no renderiza los constraints de columna.
        CheckConstraint(
            "porcentaje_avance BETWEEN 0 AND 100",
            name="seguimientos_porcentaje_avance_check",
        ),
        Index("ix_seguimientos_emprendimientoid", "emprendimientoid"),
        Index("ix_seguimientos_usuarioid", "usuarioid"),
        UniqueConstraint(
            "usuarioid",
            "referencia_cliente",
            name="uq_seguimientos_usuarioid_referencia_cliente",
        ),
    )

    estado: Mapped[str | None] = mapped_column(String(40))
    fecha: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    observaciones: Mapped[str | None] = mapped_column(Text)
    porcentaje_avance: Mapped[Decimal | None] = mapped_column(Numeric(5, 2))
    seguimiento_id: Mapped[int] = mapped_column(
        "seguimientosid", BigInteger, Identity(always=False), primary_key=True
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_seguimientos_emprendimientoid",
        ),
    )
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid", ondelete="RESTRICT", name="fk_seguimientos_usuarioid"
        ),
    )
    # Id generado por el cliente movil al registrar sin conexion (idempotencia).
    referencia_cliente: Mapped[str | None] = mapped_column(String(64))


class Recomendacion(Base):
    __tablename__ = "recomendaciones"
    __table_args__ = (
        Index("ix_recomendaciones_emprendimientoid", "emprendimientoid"),
        Index("ix_recomendaciones_usuarioid", "usuarioid"),
        Index(
            "ix_recomendaciones_sesiones_acompanamientoid", "sesiones_acompanamientoid"
        ),
    )

    contenido: Mapped[str] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    fecha: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    titulo: Mapped[str] = mapped_column(String(240))
    recomendacion_id: Mapped[int] = mapped_column(
        "recomendacionesid", BigInteger, Identity(always=False), primary_key=True
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_recomendaciones_emprendimientoid",
        ),
    )
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid",
            ondelete="RESTRICT",
            name="fk_recomendaciones_usuarioid",
        ),
    )
    sesion_acompanamiento_id: Mapped[int | None] = mapped_column(
        "sesiones_acompanamientoid",
        BigInteger,
        ForeignKey(
            "sesiones_acompanamiento.sesiones_acompanamientoid",
            ondelete="RESTRICT",
            name="fk_recomendaciones_sesiones_acompanamientoid",
        ),
    )

    sesion: Mapped[SesionAcompanamiento | None] = relationship(
        back_populates="recomendaciones"
    )


class Asignacion(Base):
    __tablename__ = "asignaciones"
    __table_args__ = (
        CheckConstraint(
            "fecha_fin IS NULL OR fecha_inicio IS NULL OR fecha_fin >= fecha_inicio",
            name="ck_asignaciones_fechas",
        ),
        Index("ix_asignaciones_usuarioid", "usuarioid"),
        Index("ix_asignaciones_emprendimientoid", "emprendimientoid"),
    )

    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_fin: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    fecha_inicio: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    tipo_asignacion: Mapped[str | None] = mapped_column(String(80))
    asignacion_id: Mapped[int] = mapped_column(
        "asignacionesid", BigInteger, Identity(always=False), primary_key=True
    )
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid", ondelete="RESTRICT", name="fk_asignaciones_usuarioid"
        ),
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_asignaciones_emprendimientoid",
        ),
    )


class PerfilMentor(Base):
    """Datos de mentoria de un usuario con rol asesor (fase 5)."""

    __tablename__ = "perfil_mentor"
    __table_args__ = (UniqueConstraint("usuarioid", name="uq_perfil_mentor_usuarioid"),)

    especialidad: Mapped[str | None] = mapped_column(String(160))
    perfil_mentor_id: Mapped[int] = mapped_column(
        "perfil_mentorid", BigInteger, Identity(always=False), primary_key=True
    )
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid", ondelete="RESTRICT", name="fk_perfil_mentor_usuarioid"
        ),
    )
    # Reto que el emprendimiento debe haber cumplido para agendar con este mentor.
    reto_requerido_id: Mapped[int | None] = mapped_column(
        "reto_requeridoid",
        BigInteger,
        ForeignKey(
            "retos.retosid",
            ondelete="RESTRICT",
            name="fk_perfil_mentor_reto_requeridoid",
        ),
    )


class DisponibilidadMentor(Base):
    """Horario semanal recurrente de un mentor (un registro por inicio de turno)."""

    __tablename__ = "disponibilidad_mentor"
    __table_args__ = (
        CheckConstraint("dia_semana BETWEEN 0 AND 6", name="ck_disponibilidad_dia"),
        CheckConstraint("duracion_min > 0", name="ck_disponibilidad_duracion"),
        UniqueConstraint(
            "usuarioid",
            "dia_semana",
            "hora_inicio",
            name="uq_disponibilidad_mentor_usuarioid_dia_hora",
        ),
        Index("ix_disponibilidad_mentor_usuarioid", "usuarioid"),
    )

    dia_semana: Mapped[int] = mapped_column(Integer)  # 0 = lunes
    duracion_min: Mapped[int] = mapped_column(Integer, default=60)
    hora_inicio: Mapped[time] = mapped_column(Time)
    disponibilidad_mentor_id: Mapped[int] = mapped_column(
        "disponibilidad_mentorid",
        BigInteger,
        Identity(always=False),
        primary_key=True,
    )
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid",
            ondelete="RESTRICT",
            name="fk_disponibilidad_mentor_usuarioid",
        ),
    )
