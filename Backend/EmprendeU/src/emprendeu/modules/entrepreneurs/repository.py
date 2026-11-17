"""Acceso a datos de entrepreneurs."""

from __future__ import annotations

from sqlalchemy import column, func, or_, select, table
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from emprendeu.modules.entrepreneurs.models import (
    Emprendedor,
    EmprendimientoEmprendedor,
    Postulacion,
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

    async def document_in_use(
        self, documento: str, excluding_usuario_id: int | None = None
    ) -> bool:
        """Hay otro emprendedor con ese documento (sin distinguir mayusculas)."""
        stmt = select(Emprendedor.emprendedor_id).where(
            func.lower(Emprendedor.documento_identidad) == documento.lower()
        )
        if excluding_usuario_id is not None:
            stmt = stmt.where(Emprendedor.usuario_id != excluding_usuario_id)
        return (await self._session.execute(stmt.limit(1))).first() is not None

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

    async def names_by_entrepreneur(self, emprendedor_ids: list[int]) -> dict[int, str]:
        """`Nombre Apellido` de varios emprendedores en una sola consulta."""
        if not emprendedor_ids:
            return {}
        stmt = (
            select(Emprendedor.emprendedor_id, _usuario.c.nombre, _usuario.c.apellido)
            .join(_usuario, _usuario.c.usuarioid == Emprendedor.usuario_id)
            .where(Emprendedor.emprendedor_id.in_(emprendedor_ids))
        )
        rows = (await self._session.execute(stmt)).all()
        return {r[0]: f"{r[1]} {r[2]}".strip() for r in rows}

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
                func.lower(func.coalesce(Emprendedor.documento_identidad, "")).like(
                    like
                ),
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

    async def active_user_ids(self) -> list[int]:
        rows = await self._session.scalars(
            select(Emprendedor.usuario_id).where(Emprendedor.estado == "activo")
        )
        return list(rows)

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

    async def members_of_ventures(
        self, emprendimiento_ids: list[int]
    ) -> list[tuple[EmprendimientoEmprendedor, Emprendedor]]:
        """Integrantes (vinculo + perfil) de varios emprendimientos, por antiguedad."""
        if not emprendimiento_ids:
            return []
        stmt = (
            select(EmprendimientoEmprendedor, Emprendedor)
            .join(
                Emprendedor,
                Emprendedor.emprendedor_id == EmprendimientoEmprendedor.emprendedor_id,
            )
            .where(EmprendimientoEmprendedor.emprendimiento_id.in_(emprendimiento_ids))
            .order_by(
                EmprendimientoEmprendedor.emprendimiento_id,
                EmprendimientoEmprendedor.emprendimiento_emprendedor_id,
            )
        )
        return [(r[0], r[1]) for r in (await self._session.execute(stmt)).all()]

    async def set_role(
        self, emprendedor_id: int, emprendimiento_id: int, rol: str | None
    ) -> bool:
        stmt = select(EmprendimientoEmprendedor).where(
            EmprendimientoEmprendedor.emprendedor_id == emprendedor_id,
            EmprendimientoEmprendedor.emprendimiento_id == emprendimiento_id,
        )
        found = (await self._session.execute(stmt)).scalar_one_or_none()
        if found is None:
            return False
        found.rol_en_emprendimiento = rol
        await self._session.flush()
        return True

    async def unlink(self, emprendedor_id: int, emprendimiento_id: int) -> bool:
        stmt = select(EmprendimientoEmprendedor).where(
            EmprendimientoEmprendedor.emprendedor_id == emprendedor_id,
            EmprendimientoEmprendedor.emprendimiento_id == emprendimiento_id,
        )
        found = (await self._session.execute(stmt)).scalar_one_or_none()
        if found is None:
            return False
        await self._session.delete(found)
        await self._session.flush()
        return True


class AdmissionRepository:
    """Postulaciones al programa (CU26)."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def rollback(self) -> None:
        await self._session.rollback()

    async def add(self, row: Postulacion) -> Postulacion:
        self._session.add(row)
        await self._session.flush()
        return row

    async def get(
        self, postulacion_id: int, *, lock: bool = False
    ) -> Postulacion | None:
        stmt = select(Postulacion).where(Postulacion.postulacion_id == postulacion_id)
        if lock:
            stmt = stmt.with_for_update()
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def pending_email_exists(self, email: str) -> bool:
        stmt = select(Postulacion.postulacion_id).where(
            func.lower(Postulacion.email) == email.lower(),
            Postulacion.estado == "pendiente",
        )
        return (await self._session.execute(stmt.limit(1))).first() is not None

    async def list(
        self, *, estado: str | None, q: str | None, offset: int, limit: int
    ) -> tuple[list[Postulacion], int]:
        stmt = select(Postulacion)
        if estado:
            stmt = stmt.where(Postulacion.estado == estado)
        if q:
            like = f"%{q.strip().lower()}%"
            stmt = stmt.where(
                or_(
                    func.lower(Postulacion.nombre).like(like),
                    func.lower(Postulacion.apellido).like(like),
                    func.lower(Postulacion.email).like(like),
                    func.lower(Postulacion.nombre_emprendimiento).like(like),
                )
            )
        total = (
            await self._session.execute(
                select(func.count()).select_from(stmt.subquery())
            )
        ).scalar_one()
        rows = (
            (
                await self._session.execute(
                    stmt.order_by(
                        # pendientes primero, y dentro de cada grupo la mas reciente
                        (Postulacion.estado != "pendiente"),
                        Postulacion.fecha_postulacion.desc(),
                    )
                    .offset(offset)
                    .limit(limit)
                )
            )
            .scalars()
            .all()
        )
        return list(rows), total
