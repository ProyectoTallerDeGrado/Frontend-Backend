"""Servicio de ventures: emprendimientos, etapas, hitos y necesidades."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import Forbidden
from emprendeu.core.pagination import PageParams
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.users import CurrentUser
from emprendeu.modules.ventures import schemas as s
from emprendeu.modules.ventures.exceptions import (
    MilestoneNotFound,
    NeedNotFound,
    StageInactive,
    StageNotFound,
    VentureNotFound,
)
from emprendeu.modules.ventures.models import (
    Emprendimiento,
    EmprendimientoEtapa,
    EmprendimientoNecesidad,
    Etapa,
    Hito,
    Necesidad,
)
from emprendeu.modules.ventures.repository import VentureRepository, now


@dataclass(frozen=True, slots=True)
class StageRef:
    """Vista publica de una etapa para otros modulos."""

    etapa_id: int
    nombre: str
    orden: int | None


def _stage_out(e: Etapa) -> s.StageOut:
    return s.StageOut(
        etapa_id=e.etapa_id,
        nombre=e.nombre,
        descripcion=e.descripcion,
        criterios=e.criterios,
        orden=e.orden,
        estado=e.estado,
    )


def _venture_out(v: Emprendimiento, stage: Etapa | None) -> s.VentureOut:
    return s.VentureOut(
        emprendimiento_id=v.emprendimiento_id,
        nombre=v.nombre,
        descripcion=v.descripcion,
        sector=v.sector,
        estado=v.estado,
        fecha_creacion=v.fecha_creacion,
        etapa_actual=_stage_out(stage) if stage else None,
    )


class VentureService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = VentureRepository(session)
        self._audit = AuditService(session)
        self._entrepreneurs = EntrepreneurService(session)

    # --- API publica para otros modulos ------------------------------------

    async def stage_catalog(self) -> list[StageRef]:
        return [
            StageRef(e.etapa_id, e.nombre, e.orden)
            for e in await self._repo.list_stages()
        ]

    async def current_stage(self, emprendimiento_id: int) -> StageRef | None:
        stage = (await self._repo.active_stages_for([emprendimiento_id])).get(
            emprendimiento_id
        )
        return StageRef(stage.etapa_id, stage.nombre, stage.orden) if stage else None

    async def names_by_ids(self, ids: list[int]) -> dict[int, str]:
        return {v.emprendimiento_id: v.nombre for v in await self._repo.get_many(ids)}

    async def active_venture_ids(self) -> list[int]:
        return await self._repo.all_active_ids()

    async def created_at(self, emprendimiento_id: int) -> datetime | None:
        venture = await self._repo.get(emprendimiento_id)
        return venture.fecha_creacion if venture else None

    async def exists(self, emprendimiento_id: int) -> bool:
        return await self._repo.get(emprendimiento_id) is not None

    # --- acceso ------------------------------------------------------------

    async def _require_access(
        self, user: CurrentUser, emprendimiento_id: int, permission: str
    ) -> None:
        if user.can_staff(permission):
            return
        if await self._entrepreneurs.is_member(user.usuario_id, emprendimiento_id):
            return
        raise Forbidden(
            "No tienes acceso a este emprendimiento.",
            details={"requerido": permission},
        )

    async def _venture(self, emprendimiento_id: int) -> Emprendimiento:
        found = await self._repo.get(emprendimiento_id)
        if found is None:
            raise VentureNotFound
        return found

    # --- etapas (catalogo) -------------------------------------------------

    async def list_stages(self) -> list[s.StageOut]:
        return [_stage_out(e) for e in await self._repo.list_stages()]

    async def set_stage_state(
        self, actor: CurrentUser, etapa_id: int, estado: str
    ) -> s.StageOut:
        stage = await self._repo.get_stage(etapa_id)
        if stage is None:
            raise StageNotFound
        before = stage.estado
        stage.estado = estado
        await self._audit.record(
            actor.usuario_id,
            "config.etapa",
            stage.nombre,
            tabla="etapas",
            id_registro=etapa_id,
            antes={"estado": before},
            despues={"estado": estado},
        )
        await self._repo.commit()
        return _stage_out(stage)

    # --- emprendimientos ---------------------------------------------------

    async def create(self, user: CurrentUser, body: s.VentureCreate) -> s.VentureOut:
        venture = Emprendimiento(
            nombre=body.nombre,
            descripcion=body.descripcion,
            sector=body.sector,
            estado="activo",
            fecha_inicio=now(),
        )
        await self._repo.add(venture)
        first = next(
            (e for e in await self._repo.list_stages() if e.estado == "activa"), None
        )
        if first is not None:
            await self._repo.add(
                EmprendimientoEtapa(
                    emprendimiento_id=venture.emprendimiento_id,
                    etapa_id=first.etapa_id,
                    estado="activa",
                    fecha_inicio=now(),
                )
            )
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if ref is not None:
            await self._entrepreneurs.link_venture(
                ref.emprendedor_id, venture.emprendimiento_id, "fundador"
            )
        await self._audit.record(
            user.usuario_id,
            "negocio.emprendimiento",
            venture.nombre,
            tabla="emprendimiento",
            id_registro=venture.emprendimiento_id,
            despues={"accion": "crear"},
        )
        await self._repo.commit()
        return _venture_out(venture, first)

    async def get(self, user: CurrentUser, emprendimiento_id: int) -> s.VentureOut:
        await self._require_access(user, emprendimiento_id, "emprendedores:consulta")
        venture = await self._venture(emprendimiento_id)
        stage = (await self._repo.active_stages_for([emprendimiento_id])).get(
            emprendimiento_id
        )
        return _venture_out(venture, stage)

    async def list(
        self, params: PageParams, q: str | None, estado: str | None
    ) -> tuple[list[s.VentureOut], int]:
        rows, total = await self._repo.list(
            q=q, estado=estado, offset=params.offset, limit=params.page_size
        )
        stages = await self._repo.active_stages_for([v.emprendimiento_id for v in rows])
        return [_venture_out(v, stages.get(v.emprendimiento_id)) for v in rows], total

    async def mine(self, user: CurrentUser) -> list[s.VentureOut]:
        ids = await self._entrepreneurs.venture_ids_of_user(user.usuario_id)
        rows = await self._repo.get_many(ids)
        stages = await self._repo.active_stages_for(ids)
        return [_venture_out(v, stages.get(v.emprendimiento_id)) for v in rows]

    async def update(
        self, user: CurrentUser, emprendimiento_id: int, body: s.VentureUpdate
    ) -> s.VentureOut:
        await self._require_access(
            user, emprendimiento_id, "emprendedores:modificacion"
        )
        venture = await self._venture(emprendimiento_id)
        changes = body.model_dump(exclude_unset=True)
        if "estado" in changes and not user.can_staff("emprendedores:modificacion"):
            changes.pop("estado")
        for key, value in changes.items():
            setattr(venture, key, value)
        venture.fecha_actualizacion = now()
        await self._audit.record(
            user.usuario_id,
            "negocio.emprendimiento",
            venture.nombre,
            tabla="emprendimiento",
            id_registro=emprendimiento_id,
            despues=changes,
        )
        await self._repo.commit()
        stage = (await self._repo.active_stages_for([emprendimiento_id])).get(
            emprendimiento_id
        )
        return _venture_out(venture, stage)

    # --- etapa del emprendimiento ------------------------------------------

    async def change_stage(
        self, user: CurrentUser, emprendimiento_id: int, body: s.StageChange
    ) -> s.VentureOut:
        venture = await self._venture(emprendimiento_id)
        stage = await self._repo.get_stage(body.etapa_id)
        if stage is None:
            raise StageNotFound
        if stage.estado != "activa":
            raise StageInactive
        current = await self._repo.active_stage_row(emprendimiento_id)
        if current is not None and current.etapa_id == stage.etapa_id:
            return _venture_out(venture, stage)
        if current is not None:
            current.estado = "completada"
            current.fecha_fin = now()
            await self._repo.flush()
        await self._repo.add(
            EmprendimientoEtapa(
                emprendimiento_id=emprendimiento_id,
                etapa_id=stage.etapa_id,
                estado="activa",
                fecha_inicio=now(),
                observaciones=body.observaciones,
            )
        )
        await self._audit.record(
            user.usuario_id,
            "negocio.etapa_emprendimiento",
            f"{venture.nombre}: {stage.nombre}",
            tabla="emprendimiento_etapas",
            id_registro=emprendimiento_id,
        )
        await self._repo.commit()
        return _venture_out(venture, stage)

    async def stage_history(
        self, user: CurrentUser, emprendimiento_id: int
    ) -> list[s.VentureStageOut]:
        await self._require_access(user, emprendimiento_id, "emprendedores:consulta")
        await self._venture(emprendimiento_id)
        return [
            s.VentureStageOut(
                emprendimiento_etapa_id=row.emprendimiento_etapa_id,
                etapa_id=row.etapa_id,
                etapa=name,
                estado=row.estado,
                fecha_inicio=row.fecha_inicio,
                fecha_fin=row.fecha_fin,
                observaciones=row.observaciones,
            )
            for row, name in await self._repo.stage_history(emprendimiento_id)
        ]

    # --- hitos -------------------------------------------------------------

    @staticmethod
    def _milestone_out(h: Hito) -> s.MilestoneOut:
        return s.MilestoneOut(
            hito_id=h.hito_id,
            emprendimiento_id=h.emprendimiento_id,
            titulo=h.titulo,
            descripcion=h.descripcion,
            estado=h.estado,
            fecha_estimada=h.fecha_estimada,
            fecha_cumplimiento=h.fecha_cumplimiento,
        )

    async def list_milestones(
        self, user: CurrentUser, emprendimiento_id: int
    ) -> list[s.MilestoneOut]:
        await self._require_access(user, emprendimiento_id, "seguimiento:consulta")
        await self._venture(emprendimiento_id)
        return [
            self._milestone_out(h)
            for h in await self._repo.list_milestones(emprendimiento_id)
        ]

    async def create_milestone(
        self, user: CurrentUser, emprendimiento_id: int, body: s.MilestoneCreate
    ) -> s.MilestoneOut:
        await self._require_access(user, emprendimiento_id, "seguimiento:registro")
        await self._venture(emprendimiento_id)
        current = await self._repo.active_stage_row(emprendimiento_id)
        milestone = Hito(
            emprendimiento_id=emprendimiento_id,
            emprendimiento_etapa_id=current.emprendimiento_etapa_id
            if current
            else None,
            titulo=body.titulo,
            descripcion=body.descripcion,
            fecha_estimada=body.fecha_estimada,
            estado="pendiente",
        )
        await self._repo.add(milestone)
        await self._repo.commit()
        return self._milestone_out(milestone)

    async def update_milestone(
        self, user: CurrentUser, hito_id: int, body: s.MilestoneUpdate
    ) -> s.MilestoneOut:
        milestone = await self._repo.get_milestone(hito_id)
        if milestone is None:
            raise MilestoneNotFound
        await self._require_access(
            user, milestone.emprendimiento_id, "seguimiento:modificacion"
        )
        milestone.estado = body.estado
        milestone.fecha_cumplimiento = now() if body.estado == "cumplido" else None
        await self._repo.commit()
        return self._milestone_out(milestone)

    # --- necesidades -------------------------------------------------------

    async def list_needs(self) -> list[s.NeedOut]:
        return [
            s.NeedOut(
                necesidad_id=n.necesidad_id, nombre=n.nombre, descripcion=n.descripcion
            )
            for n in await self._repo.list_needs()
        ]

    async def create_need(self, body: s.NeedCreate) -> s.NeedOut:
        need = Necesidad(nombre=body.nombre, descripcion=body.descripcion)
        await self._repo.add(need)
        await self._repo.commit()
        return s.NeedOut(
            necesidad_id=need.necesidad_id,
            nombre=need.nombre,
            descripcion=need.descripcion,
        )

    @staticmethod
    def _need_out(row: EmprendimientoNecesidad, name: str) -> s.VentureNeedOut:
        return s.VentureNeedOut(
            emprendimiento_necesidad_id=row.emprendimiento_necesidad_id,
            necesidad_id=row.necesidad_id,
            necesidad=name,
            estado=row.estado,
            prioridad=row.prioridad,
            fecha_detectada=row.fecha_detectada,
            fecha_resuelta=row.fecha_resuelta,
        )

    async def list_venture_needs(
        self, user: CurrentUser, emprendimiento_id: int
    ) -> list[s.VentureNeedOut]:
        await self._require_access(user, emprendimiento_id, "seguimiento:consulta")
        await self._venture(emprendimiento_id)
        return [
            self._need_out(r, n)
            for r, n in await self._repo.venture_needs(emprendimiento_id)
        ]

    async def add_venture_need(
        self, user: CurrentUser, emprendimiento_id: int, body: s.VentureNeedCreate
    ) -> s.VentureNeedOut:
        await self._require_access(user, emprendimiento_id, "seguimiento:registro")
        await self._venture(emprendimiento_id)
        need = await self._repo.get_need(body.necesidad_id)
        if need is None:
            raise NeedNotFound
        row = EmprendimientoNecesidad(
            emprendimiento_id=emprendimiento_id,
            necesidad_id=need.necesidad_id,
            estado="detectada",
            prioridad=body.prioridad,
            fecha_detectada=now(),
        )
        await self._repo.add(row)
        await self._repo.commit()
        return self._need_out(row, need.nombre)

    async def resolve_venture_need(
        self, user: CurrentUser, row_id: int
    ) -> s.VentureNeedOut:
        row = await self._repo.get_venture_need(row_id)
        if row is None:
            raise NeedNotFound
        await self._require_access(
            user, row.emprendimiento_id, "seguimiento:modificacion"
        )
        row.estado = "resuelta"
        row.fecha_resuelta = now()
        need = await self._repo.get_need(row.necesidad_id)
        await self._repo.commit()
        return self._need_out(row, need.nombre if need else "")
