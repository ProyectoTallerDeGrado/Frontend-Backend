"""Acceso a datos de ventures."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.ventures.models import (
    Emprendimiento,
    EmprendimientoEtapa,
    EmprendimientoNecesidad,
    Etapa,
    Hito,
    Necesidad,
)


def now() -> datetime:
    return datetime.now(UTC)


class VentureRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def commit(self) -> None:
        await self._session.commit()

    async def rollback(self) -> None:
        await self._session.rollback()

    async def flush(self) -> None:
        await self._session.flush()

    async def add(self, obj: object) -> None:
        self._session.add(obj)
        await self._session.flush()

    # --- etapas (catalogo) ------------------------------------------------

    async def list_stages(self) -> list[Etapa]:
        stmt = select(Etapa).order_by(Etapa.orden, Etapa.etapa_id)
        return list((await self._session.execute(stmt)).scalars().all())

    async def get_stage(self, etapa_id: int) -> Etapa | None:
        return await self._session.get(Etapa, etapa_id)

    # --- emprendimientos --------------------------------------------------

    async def get(self, emprendimiento_id: int) -> Emprendimiento | None:
        return await self._session.get(Emprendimiento, emprendimiento_id)

    async def get_many(self, ids: list[int]) -> list[Emprendimiento]:
        if not ids:
            return []
        stmt = (
            select(Emprendimiento)
            .where(Emprendimiento.emprendimiento_id.in_(ids))
            .order_by(Emprendimiento.emprendimiento_id)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def list(
        self, *, q: str | None, estado: str | None, offset: int, limit: int
    ) -> tuple[list[Emprendimiento], int]:
        conditions = []
        if q:
            like = f"%{q.strip().lower()}%"
            conditions.append(
                or_(
                    func.lower(Emprendimiento.nombre).like(like),
                    func.lower(func.coalesce(Emprendimiento.sector, "")).like(like),
                )
            )
        if estado:
            conditions.append(Emprendimiento.estado == estado)
        total = (
            await self._session.execute(
                select(func.count()).select_from(Emprendimiento).where(*conditions)
            )
        ).scalar_one()
        stmt = (
            select(Emprendimiento)
            .where(*conditions)
            .order_by(Emprendimiento.emprendimiento_id.desc())
            .offset(offset)
            .limit(limit)
        )
        return list((await self._session.execute(stmt)).scalars().all()), total

    async def all_active_ids(self) -> list[int]:
        stmt = select(Emprendimiento.emprendimiento_id).where(
            func.lower(func.coalesce(Emprendimiento.estado, "activo")) == "activo"
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def active_ventures_with_stage(
        self, etapa_id: int | None
    ) -> list[tuple[Emprendimiento, Etapa | None]]:
        """Emprendimientos activos con su etapa actual (filtrables por ella)."""
        stmt = (
            select(Emprendimiento, Etapa)
            .outerjoin(
                EmprendimientoEtapa,
                and_(
                    EmprendimientoEtapa.emprendimiento_id
                    == Emprendimiento.emprendimiento_id,
                    func.lower(EmprendimientoEtapa.estado) == "activa",
                ),
            )
            .outerjoin(Etapa, Etapa.etapa_id == EmprendimientoEtapa.etapa_id)
            .where(
                func.lower(func.coalesce(Emprendimiento.estado, "activo")) == "activo"
            )
            .order_by(Emprendimiento.nombre, Emprendimiento.emprendimiento_id)
        )
        if etapa_id is not None:
            stmt = stmt.where(Etapa.etapa_id == etapa_id)
        return [(r[0], r[1]) for r in (await self._session.execute(stmt)).all()]

    async def active_stage_since(self, ids: list[int]) -> dict[int, datetime]:
        if not ids:
            return {}
        stmt = select(
            EmprendimientoEtapa.emprendimiento_id, EmprendimientoEtapa.fecha_inicio
        ).where(
            EmprendimientoEtapa.emprendimiento_id.in_(ids),
            func.lower(EmprendimientoEtapa.estado) == "activa",
            EmprendimientoEtapa.fecha_inicio.is_not(None),
        )
        return {r[0]: r[1] for r in (await self._session.execute(stmt)).all()}

    async def stage_counts(self) -> dict[int, int]:
        """Emprendimientos activos por etapa actual."""
        stmt = (
            select(EmprendimientoEtapa.etapa_id, func.count())
            .join(
                Emprendimiento,
                Emprendimiento.emprendimiento_id
                == EmprendimientoEtapa.emprendimiento_id,
            )
            .where(
                func.lower(EmprendimientoEtapa.estado) == "activa",
                func.lower(func.coalesce(Emprendimiento.estado, "activo")) == "activo",
            )
            .group_by(EmprendimientoEtapa.etapa_id)
        )
        return {r[0]: r[1] for r in (await self._session.execute(stmt)).all()}

    # --- etapa del emprendimiento ----------------------------------------

    async def active_stage_row(
        self, emprendimiento_id: int
    ) -> EmprendimientoEtapa | None:
        stmt = select(EmprendimientoEtapa).where(
            EmprendimientoEtapa.emprendimiento_id == emprendimiento_id,
            func.lower(EmprendimientoEtapa.estado) == "activa",
        )
        return (await self._session.execute(stmt)).scalar_one_or_none()

    async def active_stages_for(self, ids: list[int]) -> dict[int, Etapa]:
        if not ids:
            return {}
        stmt = (
            select(EmprendimientoEtapa.emprendimiento_id, Etapa)
            .join(Etapa, Etapa.etapa_id == EmprendimientoEtapa.etapa_id)
            .where(
                EmprendimientoEtapa.emprendimiento_id.in_(ids),
                func.lower(EmprendimientoEtapa.estado) == "activa",
            )
        )
        return {r[0]: r[1] for r in (await self._session.execute(stmt)).all()}

    async def stage_history(
        self, emprendimiento_id: int
    ) -> list[tuple[EmprendimientoEtapa, str]]:
        stmt = (
            select(EmprendimientoEtapa, Etapa.nombre)
            .join(Etapa, Etapa.etapa_id == EmprendimientoEtapa.etapa_id)
            .where(EmprendimientoEtapa.emprendimiento_id == emprendimiento_id)
            .order_by(EmprendimientoEtapa.emprendimiento_etapa_id)
        )
        return [(r[0], r[1]) for r in (await self._session.execute(stmt)).all()]

    # --- hitos ------------------------------------------------------------

    async def list_milestones(self, emprendimiento_id: int) -> list[Hito]:
        stmt = (
            select(Hito)
            .where(Hito.emprendimiento_id == emprendimiento_id)
            .order_by(Hito.fecha_estimada.asc().nulls_last(), Hito.hito_id)
        )
        return list((await self._session.execute(stmt)).scalars().all())

    async def milestone_title_exists(self, emprendimiento_id: int, titulo: str) -> bool:
        stmt = select(Hito.hito_id).where(
            Hito.emprendimiento_id == emprendimiento_id,
            func.lower(func.trim(Hito.titulo)) == titulo.strip().lower(),
        )
        return (await self._session.execute(stmt)).first() is not None

    async def venture_need_exists(
        self, emprendimiento_id: int, necesidad_id: int
    ) -> bool:
        stmt = select(EmprendimientoNecesidad.emprendimiento_necesidad_id).where(
            EmprendimientoNecesidad.emprendimiento_id == emprendimiento_id,
            EmprendimientoNecesidad.necesidad_id == necesidad_id,
            EmprendimientoNecesidad.estado == "detectada",
        )
        return (await self._session.execute(stmt)).first() is not None

    async def get_milestone(self, hito_id: int) -> Hito | None:
        return await self._session.get(Hito, hito_id)

    # --- necesidades ------------------------------------------------------

    async def list_needs(self) -> list[Necesidad]:
        stmt = select(Necesidad).order_by(Necesidad.nombre)
        return list((await self._session.execute(stmt)).scalars().all())

    async def get_need(self, necesidad_id: int) -> Necesidad | None:
        return await self._session.get(Necesidad, necesidad_id)

    async def venture_needs(
        self, emprendimiento_id: int
    ) -> list[tuple[EmprendimientoNecesidad, str]]:
        stmt = (
            select(EmprendimientoNecesidad, Necesidad.nombre)
            .join(
                Necesidad,
                Necesidad.necesidad_id == EmprendimientoNecesidad.necesidad_id,
            )
            .where(EmprendimientoNecesidad.emprendimiento_id == emprendimiento_id)
            .order_by(EmprendimientoNecesidad.emprendimiento_necesidad_id)
        )
        return [(r[0], r[1]) for r in (await self._session.execute(stmt)).all()]

    async def list_venture_needs_all(
        self,
        *,
        estado: str | None,
        tipo: str | None,
        emprendimiento_id: int | None,
        offset: int,
        limit: int,
    ) -> tuple[list[tuple[EmprendimientoNecesidad, str, str]], int]:
        """Bandeja del personal: necesidades de todos los emprendimientos."""
        base = (
            select(EmprendimientoNecesidad, Necesidad.nombre, Emprendimiento.nombre)
            .join(
                Necesidad,
                Necesidad.necesidad_id == EmprendimientoNecesidad.necesidad_id,
            )
            .join(
                Emprendimiento,
                Emprendimiento.emprendimiento_id
                == EmprendimientoNecesidad.emprendimiento_id,
            )
        )
        if estado:
            base = base.where(EmprendimientoNecesidad.estado == estado)
        if tipo:
            base = base.where(EmprendimientoNecesidad.tipo == tipo)
        if emprendimiento_id is not None:
            base = base.where(
                EmprendimientoNecesidad.emprendimiento_id == emprendimiento_id
            )
        total = (
            await self._session.execute(
                select(func.count()).select_from(base.subquery())
            )
        ).scalar_one()
        rows = (
            await self._session.execute(
                base.order_by(
                    EmprendimientoNecesidad.estado.asc(),
                    EmprendimientoNecesidad.fecha_detectada.desc(),
                )
                .offset(offset)
                .limit(limit)
            )
        ).all()
        return [(r[0], r[1], r[2]) for r in rows], total

    async def get_venture_need(self, row_id: int) -> EmprendimientoNecesidad | None:
        return await self._session.get(EmprendimientoNecesidad, row_id)
