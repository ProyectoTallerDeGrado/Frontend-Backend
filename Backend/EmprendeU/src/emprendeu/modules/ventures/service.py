"""Servicio de ventures: emprendimientos, etapas, hitos y necesidades."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import Forbidden
from emprendeu.core.pagination import PageParams
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService, MemberRef
from emprendeu.modules.users import CurrentUser
from emprendeu.modules.ventures import schemas as s
from emprendeu.modules.ventures.exceptions import (
    AlreadyMember,
    DuplicateMember,
    EntrepreneurNotFoundForVenture,
    EntrepreneurRequired,
    InvalidStageTransition,
    LastMember,
    MemberNotFound,
    MilestoneDuplicate,
    MilestoneNotFound,
    NeedAlreadyRegistered,
    NeedNotFound,
    ReservedFields,
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


@dataclass(frozen=True, slots=True)
class VentureRef:
    """Vista publica de un emprendimiento activo para otros modulos."""

    id: int
    nombre: str
    sector: str | None
    stage: StageRef | None


def _stage_out(e: Etapa) -> s.StageOut:
    return s.StageOut(
        etapa_id=e.etapa_id,
        nombre=e.nombre,
        descripcion=e.descripcion,
        criterios=e.criterios,
        orden=e.orden,
        estado=e.estado,
    )


def _member_out(m: MemberRef) -> s.MemberOut:
    return s.MemberOut(
        emprendedor_id=m.emprendedor_id,
        usuario_id=m.usuario_id,
        nombre=m.nombre,
        apellido=m.apellido,
        email=m.email,
        rol_en_emprendimiento=m.rol_en_emprendimiento,
        fecha_ingreso=m.fecha_ingreso,
    )


def _venture_out(
    v: Emprendimiento, stage: Etapa | None, members: list[MemberRef] | None = None
) -> s.VentureOut:
    return s.VentureOut(
        emprendimiento_id=v.emprendimiento_id,
        nombre=v.nombre,
        descripcion=v.descripcion,
        sector=v.sector,
        estado=v.estado,
        fecha_creacion=v.fecha_creacion,
        etapa_actual=_stage_out(stage) if stage else None,
        integrantes=[_member_out(m) for m in members or []],
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

    async def active_stage_since(self, ids: list[int]) -> dict[int, datetime]:
        """Desde cuándo está cada emprendimiento en su etapa actual (`activa`)."""
        return await self._repo.active_stage_since(ids)

    async def exists(self, emprendimiento_id: int) -> bool:
        return await self._repo.get(emprendimiento_id) is not None

    async def active_ventures(self, etapa_id: int | None = None) -> list[VentureRef]:
        """Emprendimientos activos, opcionalmente solo los de una etapa actual."""
        return [
            VentureRef(
                v.emprendimiento_id,
                v.nombre,
                v.sector,
                StageRef(e.etapa_id, e.nombre, e.orden) if e else None,
            )
            for v, e in await self._repo.active_ventures_with_stage(etapa_id)
        ]

    async def stage_distribution(self) -> list[tuple[StageRef, int]]:
        """Cuantos emprendimientos activos hay en cada etapa (incluidas las vacias)."""
        counts = await self._repo.stage_counts()
        return [
            (StageRef(e.etapa_id, e.nombre, e.orden), counts.get(e.etapa_id, 0))
            for e in await self._repo.list_stages()
        ]

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

    async def _team_for_staff(self, body: s.VentureCreate) -> list[s.MemberIn]:
        """Equipo inicial que indica el personal: al menos un emprendedor existente."""
        team = list(body.integrantes)
        if body.emprendedor_id is not None and all(
            m.emprendedor_id != body.emprendedor_id for m in team
        ):
            team.insert(
                0,
                s.MemberIn(
                    emprendedor_id=body.emprendedor_id,
                    rol_en_emprendimiento="fundador",
                ),
            )
        if not team:
            raise EntrepreneurRequired
        seen: set[int] = set()
        for m in team:
            if m.emprendedor_id in seen:
                raise DuplicateMember(m.emprendedor_id)
            seen.add(m.emprendedor_id)
            if await self._entrepreneurs.ref_for_entrepreneur(m.emprendedor_id) is None:
                raise EntrepreneurNotFoundForVenture(m.emprendedor_id)
        return team

    async def _team_for_entrepreneur(
        self, user: CurrentUser, body: s.VentureCreate
    ) -> list[s.MemberIn]:
        """Un emprendedor solo crea emprendimientos propios y queda como fundador."""
        owner = await self._entrepreneurs.ref_for_user(user.usuario_id)
        own_id = owner.emprendedor_id if owner else None
        asked = {m.emprendedor_id for m in body.integrantes}
        if body.emprendedor_id is not None:
            asked.add(body.emprendedor_id)
        if asked - {own_id}:
            raise Forbidden("Solo puedes crear emprendimientos propios.")
        if own_id is None:
            return []
        return [s.MemberIn(emprendedor_id=own_id, rol_en_emprendimiento="fundador")]

    async def create(
        self, user: CurrentUser, body: s.VentureCreate, *, commit: bool = True
    ) -> s.VentureOut:
        # CU05: el personal crea el emprendimiento con su equipo (uno o mas
        # emprendedores); un emprendedor solo crea el suyo.
        if user.can_staff("emprendedores:registro"):
            team = await self._team_for_staff(body)
        else:
            team = await self._team_for_entrepreneur(user, body)
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
        for m in team:
            await self._entrepreneurs.link_venture(
                m.emprendedor_id, venture.emprendimiento_id, m.rol_en_emprendimiento
            )
        await self._audit.record(
            user.usuario_id,
            "negocio.emprendimiento",
            venture.nombre,
            tabla="emprendimiento",
            id_registro=venture.emprendimiento_id,
            despues={
                "accion": "crear",
                "integrantes": [m.emprendedor_id for m in team],
            },
        )
        if commit:
            await self._repo.commit()
        else:
            await self._repo.flush()
        return await self._out(venture, first)

    async def _out(self, venture: Emprendimiento, stage: Etapa | None) -> s.VentureOut:
        members = await self._entrepreneurs.members_of_ventures(
            [venture.emprendimiento_id]
        )
        return _venture_out(venture, stage, members.get(venture.emprendimiento_id))

    async def _outs(self, rows: list[Emprendimiento]) -> list[s.VentureOut]:
        ids = [v.emprendimiento_id for v in rows]
        stages = await self._repo.active_stages_for(ids)
        members = await self._entrepreneurs.members_of_ventures(ids)
        return [
            _venture_out(
                v, stages.get(v.emprendimiento_id), members.get(v.emprendimiento_id)
            )
            for v in rows
        ]

    # --- integrantes (CU05) -----------------------------------------------

    async def list_members(
        self, user: CurrentUser, emprendimiento_id: int
    ) -> list[s.MemberOut]:
        await self._require_access(user, emprendimiento_id, "emprendedores:consulta")
        await self._venture(emprendimiento_id)
        members = await self._entrepreneurs.members_of_ventures([emprendimiento_id])
        return [_member_out(m) for m in members.get(emprendimiento_id, [])]

    async def add_member(
        self, user: CurrentUser, emprendimiento_id: int, body: s.MemberIn
    ) -> list[s.MemberOut]:
        venture = await self._venture(emprendimiento_id)
        if await self._entrepreneurs.ref_for_entrepreneur(body.emprendedor_id) is None:
            raise EntrepreneurNotFoundForVenture(body.emprendedor_id)
        if not await self._entrepreneurs.link_venture(
            body.emprendedor_id, emprendimiento_id, body.rol_en_emprendimiento
        ):
            raise AlreadyMember
        await self._audit.record(
            user.usuario_id,
            "negocio.emprendimiento",
            venture.nombre,
            tabla="emprendimiento_emprendedores",
            id_registro=emprendimiento_id,
            despues={
                "accion": "agregar_integrante",
                "emprendedor_id": body.emprendedor_id,
                "rol": body.rol_en_emprendimiento,
            },
        )
        await self._repo.commit()
        return await self.list_members(user, emprendimiento_id)

    async def change_member_role(
        self,
        user: CurrentUser,
        emprendimiento_id: int,
        emprendedor_id: int,
        body: s.MemberRoleUpdate,
    ) -> list[s.MemberOut]:
        venture = await self._venture(emprendimiento_id)
        current = {
            m.emprendedor_id: m
            for m in await self.list_members(user, emprendimiento_id)
        }
        if emprendedor_id not in current:
            raise MemberNotFound
        before = current[emprendedor_id].rol_en_emprendimiento
        await self._entrepreneurs.set_member_role(
            emprendedor_id, emprendimiento_id, body.rol_en_emprendimiento
        )
        await self._audit.record(
            user.usuario_id,
            "negocio.emprendimiento",
            venture.nombre,
            tabla="emprendimiento_emprendedores",
            id_registro=emprendimiento_id,
            antes={"emprendedor_id": emprendedor_id, "rol": before},
            despues={
                "accion": "cambiar_rol_integrante",
                "rol": body.rol_en_emprendimiento,
            },
        )
        await self._repo.commit()
        return await self.list_members(user, emprendimiento_id)

    async def remove_member(
        self, user: CurrentUser, emprendimiento_id: int, emprendedor_id: int
    ) -> list[s.MemberOut]:
        venture = await self._venture(emprendimiento_id)
        current = await self._entrepreneurs.entrepreneur_ids_of_venture(
            emprendimiento_id
        )
        if emprendedor_id not in current:
            raise MemberNotFound
        if len(current) <= 1:
            raise LastMember
        await self._entrepreneurs.unlink_venture(emprendedor_id, emprendimiento_id)
        await self._audit.record(
            user.usuario_id,
            "negocio.emprendimiento",
            venture.nombre,
            tabla="emprendimiento_emprendedores",
            id_registro=emprendimiento_id,
            antes={"emprendedor_id": emprendedor_id},
            despues={"accion": "quitar_integrante"},
        )
        await self._repo.commit()
        return await self.list_members(user, emprendimiento_id)

    async def get(self, user: CurrentUser, emprendimiento_id: int) -> s.VentureOut:
        await self._require_access(user, emprendimiento_id, "emprendedores:consulta")
        venture = await self._venture(emprendimiento_id)
        stage = (await self._repo.active_stages_for([emprendimiento_id])).get(
            emprendimiento_id
        )
        return await self._out(venture, stage)

    async def list(
        self, params: PageParams, q: str | None, estado: str | None
    ) -> tuple[list[s.VentureOut], int]:
        rows, total = await self._repo.list(
            q=q, estado=estado, offset=params.offset, limit=params.page_size
        )
        return await self._outs(rows), total

    async def mine(self, user: CurrentUser) -> list[s.VentureOut]:
        ids = await self._entrepreneurs.venture_ids_of_user(user.usuario_id)
        return await self._outs(await self._repo.get_many(ids))

    async def update(
        self, user: CurrentUser, emprendimiento_id: int, body: s.VentureUpdate
    ) -> s.VentureOut:
        await self._require_access(
            user, emprendimiento_id, "emprendedores:modificacion"
        )
        venture = await self._venture(emprendimiento_id)
        changes = body.model_dump(exclude_unset=True)
        reserved = [k for k in ("estado",) if k in changes]
        if reserved and not user.can_staff("emprendedores:modificacion"):
            raise ReservedFields(reserved)
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
        return await self._out(venture, stage)

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
            return await self._out(venture, stage)
        # CU12: solo se avanza a la etapa activa inmediatamente siguiente (sin saltos
        # ni retrocesos). Sin etapa, solo se entra a la primera.
        active = [e for e in await self._repo.list_stages() if e.estado == "activa"]
        if current is None:
            expected = active[0] if active else None
        else:
            current_stage = await self._repo.get_stage(current.etapa_id)
            order = (current_stage.orden or 0) if current_stage else 0
            expected = next((e for e in active if (e.orden or 0) > order), None)
        if expected is None or expected.etapa_id != stage.etapa_id:
            raise InvalidStageTransition(expected.nombre if expected else None)
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
        return await self._out(venture, stage)

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
        if await self._repo.milestone_title_exists(emprendimiento_id, body.titulo):
            raise MilestoneDuplicate
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
        await self._audit.record(
            user.usuario_id,
            "negocio.hito",
            body.titulo,
            tabla="hito",
            id_registro=milestone.hito_id,
            despues={"accion": "crear", "emprendimiento_id": emprendimiento_id},
        )
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
        await self._audit.record(
            user.usuario_id,
            "negocio.hito",
            milestone.titulo,
            tabla="hito",
            id_registro=hito_id,
            despues={"accion": "estado", "estado": body.estado},
        )
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
            tipo=row.tipo or "necesidad",
            descripcion=row.descripcion,
            fecha_detectada=row.fecha_detectada,
            fecha_resuelta=row.fecha_resuelta,
        )

    async def list_needs_inbox(
        self,
        params: PageParams,
        estado: str | None,
        tipo: str | None,
        emprendimiento_id: int | None,
    ) -> tuple[list[s.VentureNeedInboxItem], int]:
        """Bandeja del personal con las necesidades y dificultades reportadas (CU24)."""
        rows, total = await self._repo.list_venture_needs_all(
            estado=estado,
            tipo=tipo,
            emprendimiento_id=emprendimiento_id,
            offset=params.offset,
            limit=params.page_size,
        )
        return [
            s.VentureNeedInboxItem(
                **self._need_out(row, need).model_dump(),
                emprendimiento_id=row.emprendimiento_id,
                emprendimiento=venture,
            )
            for row, need, venture in rows
        ], total

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
        if await self._repo.venture_need_exists(emprendimiento_id, need.necesidad_id):
            raise NeedAlreadyRegistered
        row = EmprendimientoNecesidad(
            emprendimiento_id=emprendimiento_id,
            necesidad_id=need.necesidad_id,
            estado="detectada",
            prioridad=body.prioridad,
            tipo=body.tipo,
            descripcion=body.descripcion,
            fecha_detectada=now(),
        )
        try:
            await self._repo.add(row)
        except IntegrityError as exc:  # peticion simultanea
            await self._repo.rollback()
            raise NeedAlreadyRegistered from exc
        await self._audit.record(
            user.usuario_id,
            "negocio.necesidad",
            need.nombre,
            tabla="emprendimiento_necesidades",
            id_registro=row.emprendimiento_necesidad_id,
            despues={
                "accion": "registrar",
                "emprendimiento_id": emprendimiento_id,
                "tipo": body.tipo,
            },
        )
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
        await self._audit.record(
            user.usuario_id,
            "negocio.necesidad",
            need.nombre if need else None,
            tabla="emprendimiento_necesidades",
            id_registro=row_id,
            despues={"accion": "resolver"},
        )
        await self._repo.commit()
        return self._need_out(row, need.nombre if need else "")
