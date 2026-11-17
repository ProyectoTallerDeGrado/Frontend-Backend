"""Tablas de notificaciones: bandeja del usuario y dispositivos para push (FCM)."""

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
)
from sqlalchemy.orm import Mapped, mapped_column

from emprendeu.db.base import Base


class Notificacion(Base):
    """Un aviso para un usuario. Se guarda siempre (bandeja de la app) y, si el
    usuario tiene dispositivos registrados, tambien se envia como push.

    `clave` evita duplicados de los avisos programados (p. ej. el recordatorio de
    una sesion): no puede repetirse para el mismo usuario.
    """

    __tablename__ = "notificaciones"
    __table_args__ = (
        UniqueConstraint("usuario_id", "clave", name="uq_notificaciones_clave"),
        Index("ix_notificaciones_usuario_fecha", "usuario_id", "creada_en"),
    )

    notificacion_id: Mapped[int] = mapped_column(
        BigInteger, Identity(always=False), primary_key=True
    )
    usuario_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("usuario.usuarioid", ondelete="CASCADE")
    )
    tipo: Mapped[str] = mapped_column(String(40))
    titulo: Mapped[str] = mapped_column(String(120))
    cuerpo: Mapped[str] = mapped_column(Text)
    # Pantalla de la app movil a la que lleva el aviso (p. ej. /mentoring/session/3).
    ruta: Mapped[str | None] = mapped_column(String(200))
    clave: Mapped[str | None] = mapped_column(String(80))
    leida_en: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    creada_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )


class DispositivoPush(Base):
    """Token de Firebase Cloud Messaging de un celular con la sesion abierta."""

    __tablename__ = "dispositivos_push"
    __table_args__ = (
        UniqueConstraint("token", name="uq_dispositivos_push_token"),
        CheckConstraint(
            "plataforma IN ('android', 'ios')", name="ck_dispositivos_push_plataforma"
        ),
        Index("ix_dispositivos_push_usuario", "usuario_id"),
    )

    dispositivo_push_id: Mapped[int] = mapped_column(
        BigInteger, Identity(always=False), primary_key=True
    )
    usuario_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("usuario.usuarioid", ondelete="CASCADE")
    )
    token: Mapped[str] = mapped_column(String(512))
    plataforma: Mapped[str] = mapped_column(String(10))
    creado_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    actualizado_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
