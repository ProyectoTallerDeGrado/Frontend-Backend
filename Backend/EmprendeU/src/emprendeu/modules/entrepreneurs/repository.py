"""Acceso a datos de entrepreneurs."""

from __future__ import annotations

from sqlalchemy import column, func, or_, select, table
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from emprendeu.modules.entrepreneurs.models import (
    Emprendedor,
    EmprendimientoEmprendedor,
)

# Lectura de nombre/correo sin importar el modelo del modulo users.
_usuario = table(
    "usuario",
    column("usuarioid"),
    column("nombre"),
    column("apellido"),
    column("email"),
    schema="cieu",
)


class EntrepreneurRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, emprendedor_id: int) -> Emprendedor | None:
        stmt = (
            select(Emprendedor)
            .where(Emprendedor.emprendedor_id == emprendedor_id)
            .options(selectinload(Emprendedor.emprendimientos))
        )
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def get_by_user(self, usuario_id: int) -> Emprendedor | None:
        stmt = (
            select(Emprendedor)
            .where(Emprendedor.usuario_id == usuario_id)
            .options(selectinload(Emprendedor.emprendimientos))
        )
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def add(self, emprendedor: Emprendedor) -> Emprendedor:
        self._session.add(emprendedor)
        await self._session.flush()
        return emprendedor

    async def identity(self, usuario_id: int) -> tuple[str, str, str] | None:
        stmt = select(_usuario.c.nombre, _usuario.c.apellido, _usuario.c.email).where(
            _usuario.c.usuarioid == usuario_id
        )
        row = (await self._session.execute(stmt)).first()
        return (row[0], row[1], row[2]) if row else None

    async def identities(
        self, usuario_ids: list[int]
    ) -> dict[int, tuple[str, str, str]]:
        """Nombre, apellido y correo de varios usuarios en una sola consulta."""
        if not usuario_ids:
            return {}
        stmt = select(
            _usuario.c.usuarioid,
            _usuario.c.nombre,
            _usuario.c.apellido,
            _usuario.c.email,
        ).where(_usuario.c.usuarioid.in_(usuario_ids))
        rows = (await self._session.execute(stmt)).all()
        return {r[0]: (r[1], r[2], r[3]) for r in rows}

    async def list(
        self, *, q: str | None, offset: int, limit: int
    ) -> tuple[list[Emprendedor], int]:
        base = select(Emprendedor).join(
            _usuario, _usuario.c.usuarioid == Emprendedor.usuario_id
        )
        count = (
            select(func.count())
            .select_from(Emprendedor)
            .join(_usuario, _usuario.c.usuarioid == Emprendedor.usuario_id)
        )
        if q:
            like = f"%{q.strip().lower()}%"
            cond = or_(
                func.lower(_usuario.c.nombre).like(like),
                func.lower(_usuario.c.apellido).like(like),
                func.lower(_usuario.c.email).like(like),
                func.coalesce(Emprendedor.documento_identidad, "").like(like),
            )
            base, count = base.where(cond), count.where(cond)
        total = (await self._session.execute(count)).scalar_one()
        rows = (
            (
                await self._session.execute(
                    base.options(selectinload(Emprendedor.emprendimientos))
                    .order_by(Emprendedor.emprendedor_id.desc())
                    .offset(offset)
                    .limit(limit)
                )
            )
            .scalars()
            .all()
        )
        return list(rows), total

    async def link(
        self, emprendedor_id: int, emprendimiento_id: int, rol: str | None
    ) -> bool:
        exists = (
            await self._session.execute(
                select(EmprendimientoEmprendedor.emprendimiento_emprendedor_id).where(
                    EmprendimientoEmprendedor.emprendedor_id == emprendedor_id,
                    EmprendimientoEmprendedor.emprendimiento_id == emprendimiento_id,
                )
            )
        ).first()
        if exists:
            return False
        self._session.add(
            EmprendimientoEmprendedor(
                emprendedor_id=emprendedor_id,
                emprendimiento_id=emprendimiento_id,
                rol_en_emprendimiento=rol,
                fecha_ingreso=func.current_timestamp(),
            )
        )
        await self._session.flush()
        return True

    async def venture_ids_of_user(self, usuario_id: int) -> list[int]:
        stmt = (
            select(EmprendimientoEmprendedor.emprendimiento_id)
            .join(
                Emprendedor,
                Emprendedor.emprendedor_id == EmprendimientoEmprendedor.emprendedor_id,
            )
            .where(Emprendedor.usuario_id == usuario_id)
            .order_by(EmprendimientoEmprendedor.emprendimiento_id)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def entrepreneur_ids_of_venture(self, emprendimiento_id: int) -> list[int]:
        stmt = select(EmprendimientoEmprendedor.emprendedor_id).where(
            EmprendimientoEmprendedor.emprendimiento_id == emprendimiento_id
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def user_ids_of_venture(self, emprendimiento_id: int) -> list[int]:
        stmt = (
            select(Emprendedor.usuario_id)
            .join(
                EmprendimientoEmprendedor,
                EmprendimientoEmprendedor.emprendedor_id == Emprendedor.emprendedor_id,
            )
            .where(EmprendimientoEmprendedor.emprendimiento_id == emprendimiento_id)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def venture_ids_of_entrepreneur(self, emprendedor_id: int) -> list[int]:
        stmt = select(EmprendimientoEmprendedor.emprendimiento_id).where(
            EmprendimientoEmprendedor.emprendedor_id == emprendedor_id
        )
        return list((await self._session.execute(stmt)).scalars().all())
