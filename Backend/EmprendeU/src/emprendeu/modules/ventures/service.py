"""Servicio de ventures: emprendimientos, etapas, hitos y necesidades."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import Forbidden
from emprendeu.core.pagination import PageParams
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.users import CurrentUser, build_user_service
from emprendeu.modules.ventures import schemas as s
from emprendeu.modules.ventures.exceptions import (
    EntrepreneurRequired,
    InvalidStageTransition,
    MilestoneNotFound,
    NeedAlreadyReported,
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
        self._session = session

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

    async def _new_venture(
        self,
        nombre: str,
        descripcion: str | None,
        sector: str | None,
        owner_id: int | None,
    ) -> tuple[Emprendimiento, Etapa | None]:
        """Emprendimiento activo, en la primera etapa activa y con su fundador. Sin commit."""
        venture = Emprendimiento(
            nombre=nombre,
            descripcion=descripcion,
            sector=sector,
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
        if owner_id is not None:
            await self._entrepreneurs.link_venture(
                owner_id, venture.emprendimiento_id, "fundador"
            )
        return venture, first

    async def admit_application(
        self, actor: CurrentUser, postulacion_id: int, observaciones: str | None
    ) -> str | None:
        """CU26: admite una postulacion. Todo o nada en una sola transaccion.

        Crea el usuario (rol emprendedor), su perfil de emprendedor, el emprendimiento
        (primera etapa, con el fundador) y vincula la postulacion. Devuelve la clave
        temporal, que solo se muestra una vez. Si algo falla no queda nada creado y la
        postulacion sigue pendiente.
        """
        try:
            application = await self._entrepreneurs.claim_application(postulacion_id)
            user, temporary = await build_user_service(
                self._session
            ).register_entrepreneur(
                actor,
                f"{application.nombre} {application.apellido}",
                application.email,
                application.documento_identidad,
                None,
                names=(application.nombre, application.apellido),
                origin="admision de postulacion",
                commit=False,
            )
            owner = await self._entrepreneurs.ref_for_user(user.usuario_id)
            if owner is None:  # no deberia pasar: la cuenta nace con su perfil
                raise EntrepreneurRequired
            venture, _ = await self._new_venture(
                application.nombre_emprendimiento,
                application.descripcion_emprendimiento,
                application.sector,
                owner.emprendedor_id,
            )
            await self._entrepreneurs.mark_admitted(
                postulacion_id,
                emprendedor_id=owner.emprendedor_id,
                emprendimiento_id=venture.emprendimiento_id,
                actor_id=actor.usuario_id,
                observaciones=observaciones,
            )
            await self._audit.record(
                actor.usuario_id,
                "negocio.postulacion",
                f"{application.nombre} {application.apellido}",
                tabla="postulaciones",
                id_registro=postulacion_id,
                despues={
                    "accion": "admitir",
                    "emprendedor_id": owner.emprendedor_id,
                    "emprendimiento_id": venture.emprendimiento_id,
                },
            )
            await self._repo.commit()
        except BaseException:
            await self._repo.rollback()
            raise
        return temporary

    async def create(self, user: CurrentUser, body: s.VentureCreate) -> s.VentureOut:
        # CU05: el personal crea el emprendimiento de un emprendedor concreto; un
        # emprendedor solo puede crear el suyo.
        if user.can_staff("emprendedores:registro"):
            if body.emprendedor_id is None:
                raise EntrepreneurRequired
            owner = await self._entrepreneurs.ref_for_entrepreneur(body.emprendedor_id)
            if owner is None:
                raise EntrepreneurRequired
        else:
            owner = await self._entrepreneurs.ref_for_user(user.usuario_id)
            if body.emprendedor_id is not None and (
                owner is None or owner.emprendedor_id != body.emprendedor_id
            ):
                raise Forbidden("Solo puedes crear emprendimientos propios.")
        venture, first = await self._new_venture(
            body.nombre,
            body.descripcion,
            body.sector,
            owner.emprendedor_id if owner else None,
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
        if body.necesidad_id is not None:
            need = await self._repo.get_need(body.necesidad_id)
            if need is None:
                raise NeedNotFound
        else:
            # CU24: si la necesidad no esta en el catalogo, se crea.
            name = body.nombre or ""
            need = await self._repo.find_need_by_name(name)
            if need is None:
                need = Necesidad(nombre=name, descripcion=body.descripcion)
                await self._repo.add(need)
        existing = await self._repo.venture_need_row(
            emprendimiento_id, need.necesidad_id
        )
        if existing is not None:
            if existing.estado != "resuelta":
                raise NeedAlreadyReported
            # una necesidad resuelta que vuelve a aparecer se reabre (la base no repite pares)
            existing.estado = "detectada"
            existing.prioridad = body.prioridad
            existing.fecha_detectada = now()
            existing.fecha_resuelta = None
            await self._repo.commit()
            return self._need_out(existing, need.nombre)
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
