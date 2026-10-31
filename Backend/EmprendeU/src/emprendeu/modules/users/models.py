"""Tablas de identidad y acceso: usuario, rol, permiso y sus asociaciones."""

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
from sqlalchemy.orm import Mapped, mapped_column, relationship

from emprendeu.db.base import Base


class Usuario(Base):
    __tablename__ = "usuario"
    __table_args__ = (
        UniqueConstraint("email", name="uq_usuario_email"),
        CheckConstraint(
            "estado IN ('habilitada', 'deshabilitada')", name="ck_usuario_estado"
        ),
    )

    apellido: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(254))
    estado: Mapped[str | None] = mapped_column(String(40), server_default="habilitada")
    fecha_actualizacion: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    fecha_registro: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.current_timestamp()
    )
    nombre: Mapped[str] = mapped_column(String(160))
    password_hash: Mapped[str | None] = mapped_column(String(255))
    telefono: Mapped[str | None] = mapped_column(String(35))
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid", BigInteger, Identity(always=False), primary_key=True
    )
    # Columna agregada despues del modelo original (migracion de la fase 1).
    ultimo_acceso: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    roles: Mapped[list[RolUsuario]] = relationship(back_populates="usuario")


class Rol(Base):
    __tablename__ = "rol"
    __table_args__ = (UniqueConstraint("nombre", name="uq_rol_nombre"),)

    descripcion: Mapped[str | None] = mapped_column(Text)
    nombre: Mapped[str] = mapped_column(String(160))
    rol_id: Mapped[int] = mapped_column(
        "rolid", BigInteger, Identity(always=False), primary_key=True
    )

    usuarios: Mapped[list[RolUsuario]] = relationship(back_populates="rol")
    permisos: Mapped[list[RolPermiso]] = relationship(back_populates="rol")


class Permiso(Base):
    __tablename__ = "permiso"
    __table_args__ = (UniqueConstraint("nombre", name="uq_permiso_nombre"),)

    nombre: Mapped[str] = mapped_column(String(160))
    permiso_id: Mapped[int] = mapped_column(
        "permisoid", BigInteger, Identity(always=False), primary_key=True
    )

    roles: Mapped[list[RolPermiso]] = relationship(back_populates="permiso")


class RolPermiso(Base):
    __tablename__ = "rol_permiso"
    __table_args__ = (
        UniqueConstraint("rolid", "permisoid", name="uq_rol_permiso_rolid_permisoid"),
        Index("ix_rol_permiso_permisoid", "permisoid"),
        Index("ix_rol_permiso_rolid", "rolid"),
    )

    rol_permiso_id: Mapped[int] = mapped_column(
        "rol_permisoid", BigInteger, Identity(always=False), primary_key=True
    )
    permiso_id: Mapped[int] = mapped_column(
        "permisoid",
        BigInteger,
        ForeignKey(
            "permiso.permisoid", ondelete="RESTRICT", name="fk_rol_permiso_permisoid"
        ),
    )
    rol_id: Mapped[int] = mapped_column(
        "rolid",
        BigInteger,
        ForeignKey("rol.rolid", ondelete="RESTRICT", name="fk_rol_permiso_rolid"),
    )

    permiso: Mapped[Permiso] = relationship(back_populates="roles")
    rol: Mapped[Rol] = relationship(back_populates="permisos")


class RolUsuario(Base):
    __tablename__ = "rol_usuario"
    __table_args__ = (
        UniqueConstraint("rolid", "usuarioid", name="uq_rol_usuario_rolid_usuarioid"),
        Index("ix_rol_usuario_rolid", "rolid"),
        Index("ix_rol_usuario_usuarioid", "usuarioid"),
    )

    rol_usuario_id: Mapped[int] = mapped_column(
        "rol_usuarioid", BigInteger, Identity(always=False), primary_key=True
    )
    rol_id: Mapped[int] = mapped_column(
        "rolid",
        BigInteger,
        ForeignKey("rol.rolid", ondelete="RESTRICT", name="fk_rol_usuario_rolid"),
    )
    usuario_id: Mapped[int] = mapped_column(
        "usuarioid",
        BigInteger,
        ForeignKey(
            "usuario.usuarioid", ondelete="RESTRICT", name="fk_rol_usuario_usuarioid"
        ),
    )

    rol: Mapped[Rol] = relationship(back_populates="usuarios")
    usuario: Mapped[Usuario] = relationship(back_populates="roles")
