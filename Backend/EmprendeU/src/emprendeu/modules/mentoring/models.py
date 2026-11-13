"""Tablas del acompanamiento: sesiones, participantes, compromisos,
seguimientos, recomendaciones y asignaciones de acompanantes."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    ForeignKeyConstraint,
    Identity,
    Index,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import ExcludeConstraint
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
        # Respaldo de la FK compuesta de `compromisos`: la sesion debe ser del
        # mismo emprendimiento que el compromiso.
        UniqueConstraint(
            "sesiones_acompanamientoid",
            "emprendimientoid",
            name="uq_sesiones_id_emprendimiento",
        ),
        Index("ix_sesiones_acompanamiento_emprendimientoid", "emprendimientoid"),
        Index("ix_sesiones_acompanamiento_tipoid", "tipoid"),
    )

    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_programada: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    fecha_realizada: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    modalidad: Mapped[str | None] = mapped_column(String(40))
    observaciones: Mapped[str | None] = mapped_column(Text)
    tema: Mapped[str | None] = mapped_column(String(250))
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
    compromisos: Mapped[list[Compromiso]] = relationship(
        back_populates="sesion",
        foreign_keys="Compromiso.sesion_acompanamiento_id",
    )
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
        ForeignKeyConstraint(
            ["sesiones_acompanamientoid", "emprendimientoid"],
            [
                "sesiones_acompanamiento.sesiones_acompanamientoid",
                "sesiones_acompanamiento.emprendimientoid",
            ],
            ondelete="RESTRICT",
            name="fk_compromisos_sesion_mismo_emp",
        ),
        Index("ix_compromisos_registrado_por", "registrado_por_usuarioid"),
        Index("ix_compromisos_responsable", "responsable_usuarioid"),
        Index("ix_compromisos_emprendimientoid", "emprendimientoid"),
        Index("ix_compromisos_sesiones_acompanamientoid", "sesiones_acompanamientoid"),
    )

    descripcion: Mapped[str | None] = mapped_column(Text)
    estado: Mapped[str | None] = mapped_column(String(40))
    fecha_completado: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    fecha_limite: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    compromiso_id: Mapped[int] = mapped_column(
        "compromisosid", BigInteger, Identity(always=False), primary_key=True
    )
    # Quien dejo registrado el compromiso (el asesor) y quien debe cumplirlo.
    registrado_por_usuario_id: Mapped[int] = mapped_column(
        "registrado_por_usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid",
            ondelete="RESTRICT",
            name="fk_compromisos_registrado_por",
        ),
    )
    responsable_usuario_id: Mapped[int] = mapped_column(
        "responsable_usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid", ondelete="RESTRICT", name="fk_compromisos_responsable"
        ),
    )
    emprendimiento_id: Mapped[int] = mapped_column(
        "emprendimientoid",
        BigInteger,
        ForeignKey(
            "emprendimiento.emprendimientoid",
            ondelete="RESTRICT",
            name="fk_compromisos_emprendimientoid",
        ),
    )
    sesion_acompanamiento_id: Mapped[int | None] = mapped_column(
        "sesiones_acompanamientoid",
        BigInteger,
        ForeignKey(
            "sesiones_acompanamiento.sesiones_acompanamientoid",
            ondelete="RESTRICT",
            name="fk_compromisos_sesiones_acompanamientoid",
        ),
    )

    sesion: Mapped[SesionAcompanamiento | None] = relationship(
        back_populates="compromisos",
        foreign_keys=[sesion_acompanamiento_id],
    )


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
        # Un asesor no puede tener dos asignaciones activas al mismo emprendimiento
        # (respaldo del chequeo del servicio ante peticiones simultaneas).
        Index(
            "uq_asignaciones_activa_usuario_emprendimiento",
            "usuarioid",
            "emprendimientoid",
            unique=True,
            postgresql_where=text("estado = 'activa'"),
        ),
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
    __table_args__ = (
        UniqueConstraint("usuarioid", name="uq_perfil_mentor_usuarioid"),
        CheckConstraint(
            "NOT habilitado OR fecha_habilitacion IS NOT NULL",
            name="ck_perfil_mentor_habilitacion",
        ),
    )

    especialidad: Mapped[str | None] = mapped_column(String(160))
    biografia: Mapped[str | None] = mapped_column(Text)
    # Solo un asesor habilitado puede recibir asignaciones y agendas (CU09, CU10).
    habilitado: Mapped[bool] = mapped_column(Boolean, server_default=text("false"))
    fecha_habilitacion: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    perfil_mentor_id: Mapped[int] = mapped_column(
        "perfilmentorid", BigInteger, Identity(always=False), primary_key=True
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
    """Intervalo concreto en que un mentor puede atender (CU15).

    La propia base impide que dos intervalos del mismo mentor se solapen.
    """

    __tablename__ = "disponibilidad_mentor"
    __table_args__ = (
        CheckConstraint(
            "estado IN ('disponible', 'bloqueado', 'reservado')",
            name="ck_disponibilidad_mentor_estado",
        ),
        CheckConstraint(
            "fecha_fin > fecha_inicio", name="ck_disponibilidad_mentor_fechas"
        ),
        ExcludeConstraint(
            ("usuarioid", "="),
            (text("tstzrange(fecha_inicio, fecha_fin)"), "&&"),
            using="gist",
            name="ex_disponibilidad_mentor_solapamiento",
        ),
    )

    fecha_inicio: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    fecha_fin: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    estado: Mapped[str] = mapped_column(String(40), server_default="disponible")
    disponibilidad_mentor_id: Mapped[int] = mapped_column(
        "disponibilidadmentorid",
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
