"""Acceso a datos del modulo users. Unico sitio con queries."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from emprendeu.modules.users.models import (
    Permiso,
    Rol,
    RolPermiso,
    RolUsuario,
    Usuario,
)

_WITH_ROLE = selectinload(Usuario.roles).selectinload(RolUsuario.rol)


class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def rollback(self) -> None:
        await self._session.rollback()

    async def flush(self) -> None:
        await self._session.flush()

    # --- usuarios ---------------------------------------------------------

    async def get_user(self, usuario_id: int) -> Usuario | None:
        stmt = (
            select(Usuario).where(Usuario.usuario_id == usuario_id).options(_WITH_ROLE)
        )
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def get_user_by_email(self, email: str) -> Usuario | None:
        stmt = (
            select(Usuario)
            .where(func.lower(Usuario.email) == email.lower())
            .options(_WITH_ROLE)
        )
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def add_user(self, usuario: Usuario, rol_id: int) -> Usuario:
        self._session.add(usuario)
        await self._session.flush()
        self._session.add(RolUsuario(usuario_id=usuario.usuario_id, rol_id=rol_id))
        await self._session.flush()
        self._session.expire(usuario, ["roles"])
        return await self._reload(usuario.usuario_id)

    async def _reload(self, usuario_id: int) -> Usuario:
        user = await self.get_user(usuario_id)
        assert user is not None
        return user

    async def touch_last_access(self, usuario: Usuario) -> None:
        usuario.ultimo_acceso = datetime.now(UTC)
        await self._session.flush()

    async def set_password(self, usuario: Usuario, password_hash: str) -> None:
        now = datetime.now(UTC)
        usuario.password_hash = password_hash
        usuario.fecha_actualizacion = now
        usuario.clave_cambiada_en = now
        await self._session.flush()

    async def set_user_role(self, usuario: Usuario, rol_id: int) -> None:
        for link in list(usuario.roles):
            await self._session.delete(link)
        await self._session.flush()
        self._session.add(RolUsuario(usuario_id=usuario.usuario_id, rol_id=rol_id))
        await self._session.flush()
        self._session.expire(usuario, ["roles"])

    async def list_by_role(self, rol: str) -> list[Usuario]:
        stmt = (
            select(Usuario)
            .where(
                Usuario.estado == "habilitada",
                Usuario.usuario_id.in_(
                    select(RolUsuario.usuario_id)
                    .join(Rol, Rol.rol_id == RolUsuario.rol_id)
                    .where(Rol.nombre == rol)
                ),
            )
            .options(_WITH_ROLE)
            .order_by(Usuario.nombre, Usuario.apellido)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def names_by_ids(self, ids: list[int]) -> dict[int, str]:
        if not ids:
            return {}
        stmt = select(Usuario.usuario_id, Usuario.nombre, Usuario.apellido).where(
            Usuario.usuario_id.in_(ids)
        )
        rows = (await self._session.execute(stmt)).all()
        return {r[0]: f"{r[1]} {r[2]}" for r in rows}

    async def stats(self) -> dict[str, int]:
        total = (
            await self._session.execute(select(func.count()).select_from(Usuario))
        ).scalar_one()
        enabled = (
            await self._session.execute(
                select(func.count())
                .select_from(Usuario)
                .where(Usuario.estado == "habilitada")
            )
        ).scalar_one()
        out = {
            "total": total,
            "habilitadas": enabled,
            "deshabilitadas": total - enabled,
        }
        for rol, count in await self.list_roles_with_counts():
            out[f"rol:{rol.nombre}"] = count
        return out

    async def set_estado(self, usuario: Usuario, estado: str) -> None:
        usuario.estado = estado
        usuario.fecha_actualizacion = datetime.now(UTC)
        await self._session.flush()

    async def list_users(
        self,
        *,
        q: str | None,
        rol: str | None,
        estado: str | None,
        offset: int,
        limit: int,
    ) -> tuple[list[Usuario], int]:
        conditions = []
        if q:
            like = f"%{q.strip().lower()}%"
            conditions.append(
                or_(
                    func.lower(Usuario.nombre).like(like),
                    func.lower(Usuario.apellido).like(like),
                    func.lower(Usuario.email).like(like),
                    func.lower(Usuario.nombre + " " + Usuario.apellido).like(like),
                )
            )
        if estado:
            conditions.append(Usuario.estado == estado)
        if rol:
            conditions.append(
                Usuario.usuario_id.in_(
                    select(RolUsuario.usuario_id)
                    .join(Rol, Rol.rol_id == RolUsuario.rol_id)
                    .where(Rol.nombre == rol)
                )
            )
        total = (
            await self._session.execute(
                select(func.count()).select_from(Usuario).where(*conditions)
            )
        ).scalar_one()
        stmt = (
            select(Usuario)
            .where(*conditions)
            .options(_WITH_ROLE)
            .order_by(Usuario.fecha_registro.desc(), Usuario.usuario_id.desc())
            .offset(offset)
            .limit(limit)
        )
        rows = (await self._session.execute(stmt)).scalars().all()
        return list(rows), total

    # --- roles y permisos -------------------------------------------------

    async def get_role_by_name(self, nombre: str) -> Rol | None:
        stmt = select(Rol).where(Rol.nombre == nombre)
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def get_role(self, rol_id: int) -> Rol | None:
        return await self._session.get(Rol, rol_id)

    async def list_roles_with_counts(self) -> list[tuple[Rol, int]]:
        stmt = (
            select(Rol, func.count(RolUsuario.rol_usuario_id))
            .outerjoin(RolUsuario, RolUsuario.rol_id == Rol.rol_id)
            .group_by(Rol.rol_id)
            .order_by(Rol.rol_id)
        )
        return [(r, int(c)) for r, c in (await self._session.execute(stmt)).all()]

    async def permission_names_for_user(self, usuario_id: int) -> frozenset[str]:
        stmt = (
            select(Permiso.nombre)
            .join(RolPermiso, RolPermiso.permiso_id == Permiso.permiso_id)
            .join(RolUsuario, RolUsuario.rol_id == RolPermiso.rol_id)
            .where(RolUsuario.usuario_id == usuario_id)
            .distinct()
        )
        return frozenset((await self._session.execute(stmt)).scalars().all())

    async def permission_names_for_role(self, rol_id: int) -> frozenset[str]:
        stmt = (
            select(Permiso.nombre)
            .join(RolPermiso, RolPermiso.permiso_id == Permiso.permiso_id)
            .where(RolPermiso.rol_id == rol_id)
        )
        return frozenset((await self._session.execute(stmt)).scalars().all())

    async def replace_role_permissions(
        self, rol_id: int, names: frozenset[str]
    ) -> None:
        current = (
            (
                await self._session.execute(
                    select(RolPermiso).where(RolPermiso.rol_id == rol_id)
                )
            )
            .scalars()
            .all()
        )
        for row in current:
            await self._session.delete(row)
        await self._session.flush()
        if names:
            ids = (
                (
                    await self._session.execute(
                        select(Permiso.permiso_id).where(Permiso.nombre.in_(names))
                    )
                )
                .scalars()
                .all()
            )
            for permiso_id in ids:
                self._session.add(RolPermiso(rol_id=rol_id, permiso_id=permiso_id))
        await self._session.flush()
