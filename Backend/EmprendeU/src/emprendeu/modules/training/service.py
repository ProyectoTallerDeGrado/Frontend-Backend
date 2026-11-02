"""Servicio de training: capacitaciones, inscripciones y asistencia."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import Forbidden, NotFoundError
from emprendeu.core.pagination import PageParams
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.training import schemas as s
from emprendeu.modules.training.exceptions import (
    AlreadyEnrolled,
    DateRequired,
    InvalidTrainingTransition,
    ParticipantNotFound,
    TrainingClosed,
    TrainingNotFound,
    TrainingNotOpen,
)
from emprendeu.modules.training.models import Capacitacion, CapacitacionParticipante
from emprendeu.modules.training.repository import TrainingRepository
from emprendeu.modules.users import CurrentUser

# Estados: borrador -> publicada -> realizada | cancelada (un borrador tambien puede cancelarse).
TRANSITIONS = {
    "borrador": {"borrador", "publicada", "cancelada"},
    "publicada": {"publicada", "realizada", "cancelada"},
    "realizada": {"realizada"},
    "cancelada": {"cancelada"},
}
OPEN_STATES = ("publicada", "realizada")


def _out(
    c: Capacitacion,
    total: int,
    enrolled: bool | None = None,
    attendance: bool | None = None,
) -> s.TrainingOut:
    return s.TrainingOut(
        capacitacion_id=c.capacitacion_id,
        titulo=c.titulo,
        descripcion=c.descripcion,
        fecha=c.fecha,
        modalidad=c.modalidad,
        tipo=c.tipo,
        estado=c.estado,
        total_inscritos=total,
        inscrito=enrolled,
        mi_asistencia=attendance,
    )


class TrainingService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = TrainingRepository(session)
        self._entrepreneurs = EntrepreneurService(session)

    async def _training(self, capacitacion_id: int) -> Capacitacion:
        found = await self._repo.get(capacitacion_id)
        if found is None:
            raise TrainingNotFound
        return found

    @staticmethod
    def _require_coordination(user: CurrentUser) -> None:
        """Crear, publicar y registrar asistencia es de coordinacion (el asesor solo consulta)."""
        if user.rol == "asesor":
            raise Forbidden("Esta accion es de coordinacion.")

    async def create(self, user: CurrentUser, body: s.TrainingCreate) -> s.TrainingOut:
        self._require_coordination(user)
        row = Capacitacion(**body.model_dump(), estado="borrador")
        await self._repo.add(row)
        await self._repo.commit()
        return _out(row, 0)

    async def update(
        self, user: CurrentUser, capacitacion_id: int, body: s.TrainingUpdate
    ) -> s.TrainingOut:
        self._require_coordination(user)
        row = await self._training(capacitacion_id)
        if row.estado in ("realizada", "cancelada"):
            raise TrainingClosed
        changes = body.model_dump(exclude_unset=True)
        if changes.get("titulo") is None:
            changes.pop("titulo", None)
        target = changes.get("estado") or row.estado
        if target not in TRANSITIONS.get(row.estado or "", set()):
            raise InvalidTrainingTransition(row.estado, str(target))
        if target == "publicada" and not changes.get("fecha", row.fecha):
            raise DateRequired
        for key, value in changes.items():
            if key == "estado" and value is None:
                continue
            setattr(row, key, value)
        await self._repo.commit()
        return _out(row, await self._repo.count_participants(capacitacion_id))

    async def get(self, user: CurrentUser, capacitacion_id: int) -> s.TrainingOut:
        row = await self._training(capacitacion_id)
        if row.estado == "borrador" and not user.can_staff("asesorias:consulta"):
            raise TrainingNotFound  # un borrador no existe para el emprendedor
        return _out(row, await self._repo.count_participants(capacitacion_id))

    async def list(
        self, user: CurrentUser, params: PageParams, estado: str | None
    ) -> tuple[list[s.TrainingOut], int]:
        """El personal ve todo; un emprendedor no ve los borradores."""
        rows, total = await self._repo.list(
            estado=estado,
            offset=params.offset,
            limit=params.page_size,
            hide_drafts=not user.can_staff("asesorias:consulta"),
        )
        return [_out(c, n) for c, n in rows], total

    async def mine(self, user: CurrentUser) -> list[s.TrainingOut]:
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if ref is None:
            return []
        return [
            _out(c, n, True, attendance)
            for c, n, attendance in await self._repo.for_entrepreneur(
                ref.emprendedor_id
            )
        ]

    async def published(self, user: CurrentUser) -> list[s.TrainingOut]:
        """CU29: capacitaciones publicadas con la inscripcion y asistencia de quien consulta."""
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if ref is None:
            return []
        return [
            _out(c, n, enrolled, attendance if enrolled else None)
            for c, n, enrolled, attendance in await self._repo.published_for(
                ref.emprendedor_id
            )
        ]

    async def enroll(self, user: CurrentUser, capacitacion_id: int) -> s.TrainingOut:
        training = await self._training(capacitacion_id)
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if ref is None:
            raise NotFoundError("Solo los emprendedores pueden inscribirse.")
        if training.estado != "publicada":
            raise TrainingNotOpen
        await self._add(training, ref.emprendedor_id)
        await self._repo.commit()
        return _out(
            training, await self._repo.count_participants(capacitacion_id), True
        )

    async def add_participant(
        self, user: CurrentUser, capacitacion_id: int, body: s.ParticipantAdd
    ) -> s.ParticipantOut:
        self._require_coordination(user)
        training = await self._training(capacitacion_id)
        if await self._entrepreneurs.ref_for_entrepreneur(body.emprendedor_id) is None:
            raise ParticipantNotFound
        row = await self._add(training, body.emprendedor_id)
        await self._repo.commit()
        return (await self._participants_out([row]))[0]

    async def _add(
        self, training: Capacitacion, emprendedor_id: int
    ) -> CapacitacionParticipante:
        if training.estado not in OPEN_STATES:
            raise TrainingNotOpen
        if await self._repo.participant(training.capacitacion_id, emprendedor_id):
            raise AlreadyEnrolled
        row = CapacitacionParticipante(
            capacitacion_id=training.capacitacion_id,
            emprendedor_id=emprendedor_id,
            asistencia=None,
            fecha_registro=datetime.now(UTC),
        )
        await self._repo.add(row)
        return row

    async def _participants_out(
        self, rows: list[CapacitacionParticipante]
    ) -> list[s.ParticipantOut]:
        people = await self._entrepreneurs.summaries([r.emprendedor_id for r in rows])
        out: list[s.ParticipantOut] = []
        for p in rows:
            name, last, email, doc = people.get(p.emprendedor_id, (None,) * 4)
            out.append(
                s.ParticipantOut(
                    capacitacion_participante_id=p.capacitacion_participante_id,
                    emprendedor_id=p.emprendedor_id,
                    asistencia=p.asistencia,
                    fecha_registro=p.fecha_registro,
                    nombre=name,
                    apellido=last,
                    email=email,
                    documento_identidad=doc,
                )
            )
        return out

    async def participants(self, capacitacion_id: int) -> list[s.ParticipantOut]:
        await self._training(capacitacion_id)
        return await self._participants_out(
            await self._repo.participants(capacitacion_id)
        )

    async def set_attendance(
        self,
        user: CurrentUser,
        capacitacion_id: int,
        emprendedor_id: int,
        body: s.AttendanceUpdate,
    ) -> s.ParticipantOut:
        self._require_coordination(user)
        training = await self._training(capacitacion_id)
        if training.estado not in OPEN_STATES:
            raise TrainingNotOpen
        row = await self._repo.participant(capacitacion_id, emprendedor_id)
        if row is None:
            raise ParticipantNotFound
        row.asistencia = body.asistio
        await self._repo.commit()
        return (await self._participants_out([row]))[0]
