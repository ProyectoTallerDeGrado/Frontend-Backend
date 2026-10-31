"""Servicio de training: capacitaciones, inscripciones y asistencia."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import DomainError, NotFoundError
from emprendeu.core.pagination import PageParams
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.training import schemas as s
from emprendeu.modules.training.exceptions import (
    AlreadyEnrolled,
    ParticipantNotFound,
    TrainingNotFound,
)
from emprendeu.modules.training.models import Capacitacion, CapacitacionParticipante
from emprendeu.modules.training.repository import TrainingRepository
from emprendeu.modules.users import CurrentUser


def _out(c: Capacitacion, total: int, enrolled: bool | None = None) -> s.TrainingOut:
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

    async def create(self, body: s.TrainingCreate) -> s.TrainingOut:
        row = Capacitacion(**body.model_dump(), estado="programada")
        await self._repo.add(row)
        await self._repo.commit()
        return _out(row, 0)

    async def update(
        self, capacitacion_id: int, body: s.TrainingUpdate
    ) -> s.TrainingOut:
        row = await self._training(capacitacion_id)
        for key, value in body.model_dump(
            exclude_unset=True, exclude_none=True
        ).items():
            setattr(row, key, value)
        await self._repo.commit()
        return _out(row, await self._repo.count_participants(capacitacion_id))

    async def list(
        self, params: PageParams, estado: str | None
    ) -> tuple[list[s.TrainingOut], int]:
        rows, total = await self._repo.list(
            estado=estado, offset=params.offset, limit=params.page_size
        )
        return [_out(c, n) for c, n in rows], total

    async def mine(self, user: CurrentUser) -> list[s.TrainingOut]:
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if ref is None:
            return []
        return [
            _out(c, n, True)
            for c, n in await self._repo.for_entrepreneur(ref.emprendedor_id)
        ]

    async def enroll(self, user: CurrentUser, capacitacion_id: int) -> s.TrainingOut:
        training = await self._training(capacitacion_id)
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if ref is None:
            raise NotFoundError("Solo los emprendedores pueden inscribirse.")
        await self._add(training, ref.emprendedor_id)
        await self._repo.commit()
        return _out(
            training, await self._repo.count_participants(capacitacion_id), True
        )

    async def add_participant(
        self, capacitacion_id: int, body: s.ParticipantAdd
    ) -> s.ParticipantOut:
        training = await self._training(capacitacion_id)
        row = await self._add(training, body.emprendedor_id)
        await self._repo.commit()
        return self._participant_out(row)

    async def _add(
        self, training: Capacitacion, emprendedor_id: int
    ) -> CapacitacionParticipante:
        if training.estado == "cancelada":
            raise DomainError("La capacitacion fue cancelada.")
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

    @staticmethod
    def _participant_out(p: CapacitacionParticipante) -> s.ParticipantOut:
        return s.ParticipantOut(
            capacitacion_participante_id=p.capacitacion_participante_id,
            emprendedor_id=p.emprendedor_id,
            asistencia=p.asistencia,
            fecha_registro=p.fecha_registro,
        )

    async def participants(self, capacitacion_id: int) -> list[s.ParticipantOut]:
        await self._training(capacitacion_id)
        return [
            self._participant_out(p)
            for p in await self._repo.participants(capacitacion_id)
        ]

    async def set_attendance(
        self, capacitacion_id: int, emprendedor_id: int, body: s.AttendanceUpdate
    ) -> s.ParticipantOut:
        await self._training(capacitacion_id)
        row = await self._repo.participant(capacitacion_id, emprendedor_id)
        if row is None:
            raise ParticipantNotFound
        row.asistencia = body.asistio
        await self._repo.commit()
        return self._participant_out(row)
