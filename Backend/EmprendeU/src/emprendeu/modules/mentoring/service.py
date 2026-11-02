"""Servicio de mentoring: mentores, agenda, sesiones, compromisos y avances."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.config import get_settings
from emprendeu.core.errors import DomainError, Forbidden
from emprendeu.core.periods import period_bounds
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurRef, EntrepreneurService
from emprendeu.modules.gamification import GamificationService
from emprendeu.modules.mentoring import schemas as s
from emprendeu.modules.mentoring.exceptions import (
    AssignmentExists,
    AssignmentNotFound,
    AvailabilityNotFound,
    AvailabilityOverlap,
    BookingNotEnabled,
    CommitmentNotFound,
    FutureDate,
    InvalidSlot,
    MentorLocked,
    MentorNotAssigned,
    MentorNotEnabled,
    MentorNotFound,
    NotAssigned,
    NoVenture,
    ResponsibleNotMember,
    SessionMismatch,
    SessionNotEditable,
    SessionNotFound,
    SlotUnavailable,
)
from emprendeu.modules.mentoring.models import (
    Asignacion,
    Compromiso,
    DisponibilidadMentor,
    PerfilMentor,
    Recomendacion,
    Seguimiento,
    SesionAcompanamiento,
    SesionParticipante,
)
from emprendeu.modules.mentoring.repository import (
    LEARNER_ROLE,
    MENTOR_ROLE,
    MentoringRepository,
    now,
)
from emprendeu.modules.users import CurrentUser, build_user_service
from emprendeu.modules.ventures import VentureService

SESSION_TYPE = "Mentoría"
ADVISOR_ROLE = "asesor"


@dataclass(frozen=True, slots=True)
class VentureActivity:
    """Actividad de mentoria de un emprendimiento (para el dashboard y los reportes)."""

    sessions_scheduled: int = 0
    sessions_done: int = 0
    sessions_cancelled: int = 0
    commitments_pending: int = 0  # hoy
    commitments_overdue: int = 0  # hoy: pendientes con fecha limite vencida
    commitments_done: int = 0  # cumplidos dentro del periodo
    progress: int = 0  # avances registrados dentro del periodo
    last_progress: datetime | None = None


STREAK_WEEKS = 4
# Duracion de cada turno que se ofrece dentro de un intervalo disponible.
SLOT_MINUTES = 60


def _tz() -> ZoneInfo:
    return ZoneInfo(get_settings().app_timezone)


class MentoringService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = MentoringRepository(session)
        self._audit = AuditService(session)
        self._users = build_user_service(session)
        self._entrepreneurs = EntrepreneurService(session)
        self._ventures = VentureService(session)
        self._gamification = GamificationService(session)

    # --- API publica para otros modulos --------------------------------------

    async def overdue_by_venture(self) -> dict[int, int]:
        return await self._repo.overdue_by_venture(now())

    async def last_activity_by_venture(self) -> dict[int, datetime]:
        return await self._repo.last_activity_by_venture()

    async def activity_by_venture(
        self, ids: list[int], desde: date | None, hasta: date | None
    ) -> dict[int, VentureActivity]:
        """Sesiones, compromisos y avances de cada emprendimiento en el periodo."""
        start, end = period_bounds(desde, hasta)
        sessions = await self._repo.session_counts(ids, start, end)
        commitments = await self._repo.commitment_counts(ids, start, end, now())
        progress, last = await self._repo.progress_stats(ids, start, end)
        out: dict[int, VentureActivity] = {}
        for venture_id in ids:
            by_state = sessions.get(venture_id, {})
            by_commitment = commitments.get(venture_id, {})
            out[venture_id] = VentureActivity(
                sessions_scheduled=by_state.get("programada", 0),
                sessions_done=by_state.get("realizada", 0),
                sessions_cancelled=by_state.get("cancelada", 0),
                commitments_pending=by_commitment.get("pendientes", 0),
                commitments_overdue=by_commitment.get("vencidos", 0),
                commitments_done=by_commitment.get("cumplidos", 0),
                progress=progress.get(venture_id, 0),
                last_progress=last.get(venture_id),
            )
        return out

    async def report_sessions(
        self, ids: list[int], desde: date | None, hasta: date | None
    ) -> list[s.SessionOut]:
        """Sesiones de esos emprendimientos en el periodo, la mas reciente primero."""
        start, end = period_bounds(desde, hasta)
        return await self._sessions_out(
            await self._repo.sessions_of_ventures(ids, start, end)
        )

    # --- utilidades -----------------------------------------------------------

    async def _venture_for(
        self, user: CurrentUser, emprendimiento_id: int | None
    ) -> tuple[int, EntrepreneurRef | None]:
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if emprendimiento_id is None:
            if ref is None or ref.primary_venture_id is None:
                raise NoVenture
            return ref.primary_venture_id, ref
        member = ref is not None and emprendimiento_id in ref.emprendimiento_ids
        if not (member or user.can_staff("seguimiento:consulta")):
            raise Forbidden("No tienes acceso a este emprendimiento.")
        return emprendimiento_id, ref

    async def _challenge_titles(self) -> dict[int, str]:
        return {c.reto_id: c.titulo for c in await self._gamification.list_challenges()}

    # --- mentores ---------------------------------------------------------------

    async def list_mentors(
        self, user: CurrentUser, emprendimiento_id: int | None
    ) -> list[s.MentorOut]:
        """Personal: todos los asesores. Emprendedor: solo los asignados y habilitados."""
        mentors = await self._users.mentors()
        profiles = await self._repo.profiles()
        venture_id: int | None = None
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if emprendimiento_id is not None:
            if not user.is_staff and not (
                ref is not None and emprendimiento_id in ref.emprendimiento_ids
            ):
                raise Forbidden("No tienes acceso a este emprendimiento.")
            venture_id = emprendimiento_id
        elif ref is not None:
            venture_id = ref.primary_venture_id
        if not user.is_staff:
            assigned = (
                set(await self._repo.assigned_mentor_ids(venture_id))
                if venture_id is not None
                else set()
            )
            mentors = [
                m
                for m in mentors
                if m.usuario_id in assigned
                and (p := profiles.get(m.usuario_id)) is not None
                and p.habilitado
            ]
        titles = await self._challenge_titles()
        out: list[s.MentorOut] = []
        for m in mentors:
            profile = profiles.get(m.usuario_id)
            required = profile.reto_requerido_id if profile else None
            locked = False
            reason = None
            if required and venture_id is not None:
                locked = not await self._gamification.is_challenge_completed(
                    venture_id, required
                )
                if locked:
                    reason = f"Se desbloquea al completar «{titles.get(required, 'un reto')}»"
            out.append(
                s.MentorOut(
                    usuario_id=m.usuario_id,
                    nombre=f"{m.nombre} {m.apellido}",
                    especialidad=profile.especialidad if profile else None,
                    habilitado=bool(profile and profile.habilitado),
                    bloqueado=locked,
                    motivo_bloqueo=reason,
                )
            )
        return out

    async def set_mentor_enabled(
        self, actor: CurrentUser, mentor_id: int, enabled: bool
    ) -> s.MentorOut:
        """Habilita o inhabilita a un asesor (CU09: solo los habilitados reciben asignaciones)."""
        self._require_coordination(actor)
        await self._mentor(mentor_id)
        profile = await self._repo.profile(mentor_id)
        if profile is None:
            profile = PerfilMentor(usuario_id=mentor_id, habilitado=False)
        before = profile.habilitado
        profile.habilitado = enabled
        if enabled:
            profile.fecha_habilitacion = now()
        await self._repo.add(profile)
        await self._audit.record(
            actor.usuario_id,
            "negocio.habilitar_asesor",
            (await self._users.names_by_ids([mentor_id])).get(mentor_id),
            tabla="perfil_mentor",
            id_registro=mentor_id,
            antes={"habilitado": before},
            despues={"habilitado": enabled},
        )
        await self._repo.commit()
        for m in await self.list_mentors(actor, None):
            if m.usuario_id == mentor_id:
                return m
        raise MentorNotFound

    # --- alcance del asesor ---------------------------------------------------------

    @staticmethod
    def _require_coordination(actor: CurrentUser) -> None:
        """Asignar y habilitar asesores es de coordinacion, no de otro asesor."""
        if actor.rol == ADVISOR_ROLE:
            raise Forbidden("Solo coordinacion asigna y habilita asesores.")

    async def _require_work_on(
        self, user: CurrentUser, venture_id: int, permission: str
    ) -> None:
        """Personal con el permiso; un asesor ademas debe estar asignado al emprendimiento."""
        if not user.can_staff(permission):
            raise Forbidden(
                "No tienes permiso para esta accion.",
                details={"requerido": permission},
            )
        if (
            user.rol == ADVISOR_ROLE
            and await self._repo.active_assignment(user.usuario_id, venture_id) is None
        ):
            raise NotAssigned

    async def _session_of(
        self, sesion_id: int | None, venture_id: int
    ) -> SesionAcompanamiento | None:
        if sesion_id is None:
            return None
        row = await self._load(sesion_id)
        if row.emprendimiento_id != venture_id:
            raise SessionMismatch
        return row

    async def _is_venture_responsible(self, usuario_id: int, venture_id: int) -> bool:
        """Emprendedor inscrito en el emprendimiento o asesor asignado a el."""
        if await self._entrepreneurs.is_member(usuario_id, venture_id):
            return True
        return await self._repo.active_assignment(usuario_id, venture_id) is not None

    async def _mentor(self, usuario_id: int) -> object:
        for m in await self._users.mentors():
            if m.usuario_id == usuario_id:
                return m
        raise MentorNotFound

    def _can_manage_mentor(self, user: CurrentUser, mentor_id: int) -> bool:
        return user.usuario_id == mentor_id or user.can_staff("asesorias:modificacion")

    async def set_profile(
        self, user: CurrentUser, mentor_id: int, body: s.MentorProfileUpdate
    ) -> s.MentorOut:
        if not self._can_manage_mentor(user, mentor_id):
            raise Forbidden("No puedes editar este perfil.")
        await self._mentor(mentor_id)
        profile = await self._repo.profile(mentor_id)
        if profile is None:
            profile = PerfilMentor(usuario_id=mentor_id, habilitado=False)
        profile.especialidad = body.especialidad
        profile.reto_requerido_id = body.reto_requerido_id
        await self._repo.add(profile)
        await self._repo.commit()
        for m in await self.list_mentors(user, None):
            if m.usuario_id == mentor_id:
                return m
        raise MentorNotFound

    @staticmethod
    def _aware(moment: datetime) -> datetime:
        return moment if moment.tzinfo else moment.replace(tzinfo=UTC)

    @staticmethod
    def _availability_out(a: DisponibilidadMentor) -> s.AvailabilityOut:
        return s.AvailabilityOut(
            disponibilidad_id=a.disponibilidad_mentor_id,
            fecha_inicio=a.fecha_inicio,
            fecha_fin=a.fecha_fin,
            estado=a.estado,  # type: ignore[arg-type]
        )

    async def get_availability(self, mentor_id: int) -> list[s.AvailabilityOut]:
        await self._mentor(mentor_id)
        return [
            self._availability_out(a) for a in await self._repo.availability(mentor_id)
        ]

    async def set_availability(
        self, user: CurrentUser, mentor_id: int, items: list[s.AvailabilityItem]
    ) -> list[s.AvailabilityOut]:
        """Reemplaza la disponibilidad. Todo o nada: un solapamiento no guarda nada."""
        if not self._can_manage_mentor(user, mentor_id):
            raise Forbidden("No puedes editar esta disponibilidad.")
        await self._mentor(mentor_id)
        ordered = sorted(items, key=lambda i: self._aware(i.fecha_inicio))
        for before, after in zip(ordered, ordered[1:], strict=False):
            if self._aware(after.fecha_inicio) < self._aware(before.fecha_fin):
                raise AvailabilityOverlap
        try:
            await self._repo.replace_availability(
                mentor_id,
                [
                    DisponibilidadMentor(
                        usuario_id=mentor_id,
                        fecha_inicio=self._aware(i.fecha_inicio),
                        fecha_fin=self._aware(i.fecha_fin),
                        estado=i.estado,
                    )
                    for i in ordered
                ],
            )
            await self._repo.commit()
        except IntegrityError as exc:  # la base tambien impide los solapamientos
            await self._repo.rollback()
            raise AvailabilityOverlap from exc
        return await self.get_availability(mentor_id)

    async def add_availability(
        self, user: CurrentUser, mentor_id: int, item: s.AvailabilityItem
    ) -> s.AvailabilityOut:
        """Agrega un horario (CU15). Si se solapa con otro responde 409 y no guarda nada."""
        if not self._can_manage_mentor(user, mentor_id):
            raise Forbidden("No puedes editar esta disponibilidad.")
        await self._mentor(mentor_id)
        row = DisponibilidadMentor(
            usuario_id=mentor_id,
            fecha_inicio=self._aware(item.fecha_inicio),
            fecha_fin=self._aware(item.fecha_fin),
            estado=item.estado,
        )
        try:
            await self._repo.add(row)
            await self._repo.commit()
        except IntegrityError as exc:
            await self._repo.rollback()
            raise AvailabilityOverlap from exc
        return self._availability_out(row)

    async def _availability_row(
        self, user: CurrentUser, disponibilidad_id: int
    ) -> DisponibilidadMentor:
        row = await self._repo.get_availability_row(disponibilidad_id)
        if row is None:
            raise AvailabilityNotFound
        if not self._can_manage_mentor(user, row.usuario_id):
            raise Forbidden("No puedes editar esta disponibilidad.")
        return row

    async def update_availability(
        self,
        user: CurrentUser,
        disponibilidad_id: int,
        body: s.AvailabilityUpdate,
    ) -> s.AvailabilityOut:
        row = await self._availability_row(user, disponibilidad_id)
        start = (
            self._aware(body.fecha_inicio) if body.fecha_inicio else row.fecha_inicio
        )
        end = self._aware(body.fecha_fin) if body.fecha_fin else row.fecha_fin
        if end <= start:
            raise DomainError("fecha_fin debe ser posterior a fecha_inicio.")
        row.fecha_inicio, row.fecha_fin = start, end
        if body.estado is not None:
            row.estado = body.estado
        try:
            await self._repo.add(row)
            await self._repo.commit()
        except IntegrityError as exc:
            await self._repo.rollback()
            raise AvailabilityOverlap from exc
        return self._availability_out(row)

    async def delete_availability(
        self, user: CurrentUser, disponibilidad_id: int
    ) -> None:
        row = await self._availability_row(user, disponibilidad_id)
        await self._repo.delete_availability_row(row)
        await self._repo.commit()

    async def _slot_starts(self, mentor_id: int, day: date) -> list[datetime]:
        """Inicios (UTC) de los turnos de `SLOT_MINUTES` que caen en `day` local."""
        tz = _tz()
        day_start = datetime.combine(day, time(0), tz).astimezone(UTC)
        day_end = datetime.combine(day + timedelta(days=1), time(0), tz).astimezone(UTC)
        step = timedelta(minutes=SLOT_MINUTES)
        starts: set[datetime] = set()
        for a in await self._repo.open_availability_between(
            mentor_id, day_start, day_end
        ):
            cursor = a.fecha_inicio.astimezone(UTC)
            limit = a.fecha_fin.astimezone(UTC)
            while cursor + step <= limit:
                if day_start <= cursor < day_end:
                    starts.add(cursor)
                cursor += step
        return sorted(starts)

    async def slots(self, mentor_id: int, day: date) -> list[s.SlotOut]:
        await self._mentor(mentor_id)
        tz = _tz()
        starts = await self._slot_starts(mentor_id, day)
        step = timedelta(minutes=SLOT_MINUTES)
        booked = (
            await self._repo.mentor_sessions_between(
                mentor_id, starts[0], starts[-1] + step
            )
            if starts
            else []
        )
        moment = now()
        out: list[s.SlotOut] = []
        for begin in starts:
            busy = any(
                b.fecha_programada is not None
                and begin <= b.fecha_programada < begin + step
                for b in booked
            )
            out.append(
                s.SlotOut(
                    inicio=begin,
                    hora=begin.astimezone(tz).strftime("%H:%M"),
                    disponible=not busy and begin > moment,
                )
            )
        return out

    # --- agendamiento -----------------------------------------------------------

    async def booking_status(
        self, user: CurrentUser, emprendimiento_id: int | None
    ) -> s.BookingStatus:
        venture_id, _ = await self._venture_for(user, emprendimiento_id)
        stage = await self._ventures.current_stage(venture_id)
        minimum = get_settings().booking_min_stage_order
        if stage is not None and (stage.orden or 0) >= minimum:
            return s.BookingStatus(habilitado=True, motivo=None, etapa=stage.nombre)
        needed = next(
            (
                e.nombre
                for e in await self._ventures.stage_catalog()
                if e.orden == minimum
            ),
            "la siguiente etapa",
        )
        return s.BookingStatus(
            habilitado=False,
            motivo=f"Avanza hasta {needed} para habilitar el agendamiento.",
            etapa=stage.nombre if stage else None,
        )

    async def book(self, user: CurrentUser, body: s.SessionCreate) -> s.SessionOut:
        venture_id, ref = await self._venture_for(user, body.emprendimiento_id)
        if ref is None or venture_id not in ref.emprendimiento_ids:
            raise Forbidden("Solo un miembro del emprendimiento puede agendar.")
        status = await self.booking_status(user, venture_id)
        if not status.habilitado:
            raise BookingNotEnabled(status.motivo or "Agendamiento no habilitado.")
        await self._mentor(body.mentor_id)
        profile = await self._repo.profile(body.mentor_id)
        if profile is None or not profile.habilitado:
            raise MentorNotEnabled
        if await self._repo.active_assignment(body.mentor_id, venture_id) is None:
            raise MentorNotAssigned
        if profile.reto_requerido_id:
            if not await self._gamification.is_challenge_completed(
                venture_id, profile.reto_requerido_id
            ):
                titles = await self._challenge_titles()
                raise MentorLocked(
                    "Se desbloquea al completar "
                    f"«{titles.get(profile.reto_requerido_id, 'un reto')}»"
                )
        start = body.inicio if body.inicio.tzinfo else body.inicio.replace(tzinfo=UTC)
        start = start.astimezone(UTC).replace(microsecond=0)
        local_day = start.astimezone(_tz()).date()
        if start not in await self._slot_starts(body.mentor_id, local_day):
            raise InvalidSlot
        if start <= now():
            raise InvalidSlot
        busy = await self._repo.mentor_sessions_between(
            body.mentor_id, start, start + timedelta(minutes=SLOT_MINUTES)
        )
        if busy:
            raise SlotUnavailable
        tipo = await self._repo.tipo_by_name(SESSION_TYPE)
        if tipo is None:
            raise DomainError(
                "Falta el tipo de sesión Mentoría (migraciones pendientes)."
            )
        session = SesionAcompanamiento(
            emprendimiento_id=venture_id,
            tipo_id=tipo.tipo_id,
            estado="programada",
            fecha_programada=start,
            tema=body.tema or (profile.especialidad if profile else None),
            modalidad="presencial",
        )
        try:
            await self._repo.add(session)
            await self._repo.add(
                SesionParticipante(
                    sesion_acompanamiento_id=session.sesion_acompanamiento_id,
                    usuario_id=body.mentor_id,
                    rol_participante=MENTOR_ROLE,
                )
            )
            await self._repo.add(
                SesionParticipante(
                    sesion_acompanamiento_id=session.sesion_acompanamiento_id,
                    usuario_id=user.usuario_id,
                    rol_participante=LEARNER_ROLE,
                )
            )
            await self._repo.commit()
        except IntegrityError as exc:
            raise SlotUnavailable from exc
        return (await self._sessions_out([session]))[0]

    # --- sesiones ---------------------------------------------------------------

    async def _sessions_out(
        self, rows: list[SesionAcompanamiento]
    ) -> list[s.SessionOut]:
        ids = [r.sesion_acompanamiento_id for r in rows]
        parts = await self._repo.participants(ids)
        counts = await self._repo.counts(ids)
        user_ids = sorted({p.usuario_id for ps in parts.values() for p in ps})
        names = await self._users.names_by_ids(user_ids)
        venture_names = await self._ventures.names_by_ids(
            sorted({r.emprendimiento_id for r in rows})
        )
        profiles = await self._repo.profiles()
        out: list[s.SessionOut] = []
        for r in rows:
            sid = r.sesion_acompanamiento_id
            people = parts.get(sid, [])
            mentor = next(
                (p for p in people if p.rol_participante == MENTOR_ROLE), None
            )
            recs, coms = counts.get(sid, (0, 0))
            profile = profiles.get(mentor.usuario_id) if mentor else None
            out.append(
                s.SessionOut(
                    sesion_id=sid,
                    emprendimiento_id=r.emprendimiento_id,
                    estado=r.estado,
                    tema=r.tema,
                    modalidad=r.modalidad,
                    fecha_programada=r.fecha_programada,
                    fecha_realizada=r.fecha_realizada,
                    observaciones=r.observaciones,
                    participantes=[
                        s.ParticipantOut(
                            usuario_id=p.usuario_id,
                            nombre=names.get(p.usuario_id),
                            rol=p.rol_participante,
                        )
                        for p in people
                    ],
                    mentor=names.get(mentor.usuario_id) if mentor else None,
                    especialidad=profile.especialidad if profile else None,
                    emprendimiento=venture_names.get(r.emprendimiento_id),
                    total_recomendaciones=recs,
                    total_compromisos=coms,
                )
            )
        return out

    async def _load(self, sesion_id: int) -> SesionAcompanamiento:
        found = await self._repo.get_session(sesion_id)
        if found is None:
            raise SessionNotFound
        return found

    async def _participant(
        self, user: CurrentUser, sesion_id: int
    ) -> SesionParticipante | None:
        parts = (await self._repo.participants([sesion_id]))[sesion_id]
        return next((p for p in parts if p.usuario_id == user.usuario_id), None)

    @staticmethod
    def _range(
        desde: date | None, hasta: date | None
    ) -> tuple[datetime | None, datetime | None]:
        """Dias locales (inclusive) -> `[inicio, fin)` en UTC."""
        tz = _tz()
        start = datetime.combine(desde, time(0), tz).astimezone(UTC) if desde else None
        end = (
            datetime.combine(hasta + timedelta(days=1), time(0), tz).astimezone(UTC)
            if hasta
            else None
        )
        return start, end

    async def my_sessions(
        self,
        user: CurrentUser,
        filtro: str | None,
        estado: str | None = None,
        desde: date | None = None,
        hasta: date | None = None,
    ) -> list[s.SessionOut]:
        estados = {
            "proximas": ["programada"],
            "realizadas": ["realizada"],
            "canceladas": ["cancelada"],
        }.get(filtro or "")
        if estado:
            estados = [estado]
        start, end = self._range(desde, hasta)
        rows = await self._repo.sessions_for_user(user.usuario_id, estados, start, end)
        if filtro == "proximas":
            rows.sort(key=lambda r: r.fecha_programada or now())
        return await self._sessions_out(rows)

    async def list_sessions(
        self,
        offset: int,
        limit: int,
        estado: str | None,
        desde: date | None = None,
        hasta: date | None = None,
        emprendimiento_id: int | None = None,
    ) -> tuple[list[s.SessionOut], int]:
        start, end = self._range(desde, hasta)
        rows, total = await self._repo.list_sessions(
            estado=estado,
            desde=start,
            hasta=end,
            emprendimiento_id=emprendimiento_id,
            offset=offset,
            limit=limit,
        )
        return await self._sessions_out(rows), total

    async def get_session(self, user: CurrentUser, sesion_id: int) -> s.SessionOut:
        row = await self._load(sesion_id)
        if not (
            await self._participant(user, sesion_id)
            or user.can_staff("asesorias:consulta")
        ):
            raise Forbidden("No participas en esta sesion.")
        return (await self._sessions_out([row]))[0]

    def _not_future(self, moment: datetime) -> datetime:
        """La fecha realizada es de algo que ya ocurrio (tolerancia de 1 minuto)."""
        when = self._aware(moment)
        if when > now() + timedelta(minutes=1):
            raise FutureDate
        return when

    async def complete_session(
        self, user: CurrentUser, sesion_id: int, body: s.SessionComplete
    ) -> s.SessionOut:
        row = await self._load(sesion_id)
        me = await self._participant(user, sesion_id)
        if not (
            (me and me.rol_participante == MENTOR_ROLE)
            or user.can_staff("asesorias:modificacion")
        ):
            raise Forbidden("Solo el mentor puede registrar la sesion.")
        if row.estado != "programada":
            raise SessionNotEditable
        when = self._not_future(body.fecha_realizada) if body.fecha_realizada else now()
        row.estado = "realizada"
        row.fecha_realizada = when
        row.observaciones = body.observaciones
        if body.tema:
            row.tema = body.tema
        if body.modalidad:
            row.modalidad = body.modalidad
        for p in (await self._repo.participants([sesion_id]))[sesion_id]:
            if p.rol_participante == LEARNER_ROLE:
                await self._gamification.award_event(p.usuario_id, "session_attended")
        await self._audit.record(
            user.usuario_id,
            "negocio.sesion",
            row.tema,
            tabla="sesiones_acompanamiento",
            id_registro=sesion_id,
            despues={"accion": "completar"},
        )
        await self._repo.commit()
        return (await self._sessions_out([row]))[0]

    async def register_session(
        self, user: CurrentUser, body: s.SessionRegister
    ) -> s.SessionOut:
        """Registra una sesion que ya ocurrio y no se agendo en la app (CU16)."""
        if not await self._ventures.exists(body.emprendimiento_id):
            raise DomainError("Emprendimiento inexistente.")
        await self._require_work_on(user, body.emprendimiento_id, "asesorias:registro")
        when = self._not_future(body.fecha_realizada)
        tipo = await self._repo.tipo_by_name(SESSION_TYPE)
        if tipo is None:
            raise DomainError(
                "Falta el tipo de sesión Mentoría (migraciones pendientes)."
            )
        row = SesionAcompanamiento(
            emprendimiento_id=body.emprendimiento_id,
            tipo_id=tipo.tipo_id,
            estado="realizada",
            fecha_programada=when,
            fecha_realizada=when,
            tema=body.tema,
            modalidad=body.modalidad,
            observaciones=body.observaciones,
        )
        await self._repo.add(row)
        sid = row.sesion_acompanamiento_id
        if user.rol == ADVISOR_ROLE:
            await self._repo.add(
                SesionParticipante(
                    sesion_acompanamiento_id=sid,
                    usuario_id=user.usuario_id,
                    rol_participante=MENTOR_ROLE,
                )
            )
        for learner in await self._entrepreneurs.user_ids_of_venture(
            body.emprendimiento_id
        ):
            await self._repo.add(
                SesionParticipante(
                    sesion_acompanamiento_id=sid,
                    usuario_id=learner,
                    rol_participante=LEARNER_ROLE,
                )
            )
            await self._gamification.award_event(learner, "session_attended")
        await self._audit.record(
            user.usuario_id,
            "negocio.sesion",
            body.tema,
            tabla="sesiones_acompanamiento",
            id_registro=sid,
            despues={
                "accion": "registrar",
                "emprendimiento_id": body.emprendimiento_id,
            },
        )
        await self._repo.commit()
        return (await self._sessions_out([row]))[0]

    async def cancel_session(self, user: CurrentUser, sesion_id: int) -> s.SessionOut:
        row = await self._load(sesion_id)
        if not (
            await self._participant(user, sesion_id)
            or user.can_staff("asesorias:modificacion")
        ):
            raise Forbidden("No participas en esta sesion.")
        if row.estado != "programada":
            raise SessionNotEditable
        row.estado = "cancelada"
        await self._repo.commit()
        return (await self._sessions_out([row]))[0]

    # --- compromisos -------------------------------------------------------------

    @staticmethod
    def _commitment_out(c: Compromiso) -> s.CommitmentOut:
        return s.CommitmentOut(
            compromiso_id=c.compromiso_id,
            emprendimiento_id=c.emprendimiento_id,
            responsable_id=c.responsable_usuario_id,
            sesion_id=c.sesion_acompanamiento_id,
            descripcion=c.descripcion,
            estado=c.estado,
            fecha_limite=c.fecha_limite,
            fecha_completado=c.fecha_completado,
        )

    async def _save_commitment(
        self,
        user: CurrentUser,
        venture_id: int,
        sesion_id: int | None,
        description: str,
        responsible: int,
        due: datetime | None,
    ) -> s.CommitmentOut:
        if not await self._is_venture_responsible(responsible, venture_id):
            raise ResponsibleNotMember
        limit = due or now() + timedelta(days=await self._repo.commitment_days())
        commitment = Compromiso(
            sesion_acompanamiento_id=sesion_id,
            emprendimiento_id=venture_id,
            registrado_por_usuario_id=user.usuario_id,
            responsable_usuario_id=responsible,
            descripcion=description,
            fecha_limite=self._aware(limit),
            estado="pendiente",
        )
        await self._repo.add(commitment)
        await self._repo.commit()
        return self._commitment_out(commitment)

    async def create_commitment(
        self, user: CurrentUser, sesion_id: int, body: s.CommitmentCreate
    ) -> s.CommitmentOut:
        """Compromiso de una sesion; el responsable por defecto es el emprendedor."""
        session_row = await self._load(sesion_id)
        me = await self._participant(user, sesion_id)
        if not (
            (me and me.rol_participante == MENTOR_ROLE)
            or user.can_staff("asesorias:registro")
        ):
            raise Forbidden("Solo el mentor puede asignar compromisos.")
        parts = (await self._repo.participants([sesion_id]))[sesion_id]
        learners = [p.usuario_id for p in parts if p.rol_participante == LEARNER_ROLE]
        responsible = body.usuario_id or (learners[0] if learners else None)
        if responsible is None:
            raise ResponsibleNotMember
        return await self._save_commitment(
            user,
            session_row.emprendimiento_id,
            sesion_id,
            body.descripcion,
            responsible,
            body.fecha_limite,
        )

    async def register_commitment(
        self, user: CurrentUser, body: s.CommitmentRegister
    ) -> s.CommitmentOut:
        """Compromiso de un emprendimiento, con o sin sesion (CU18)."""
        if not await self._ventures.exists(body.emprendimiento_id):
            raise DomainError("Emprendimiento inexistente.")
        await self._require_work_on(user, body.emprendimiento_id, "asesorias:registro")
        await self._session_of(body.sesion_id, body.emprendimiento_id)
        return await self._save_commitment(
            user,
            body.emprendimiento_id,
            body.sesion_id,
            body.descripcion,
            body.usuario_id,
            body.fecha_limite,
        )

    async def my_commitments(
        self, user: CurrentUser, estado: str | None
    ) -> list[s.CommitmentOut]:
        return [
            self._commitment_out(c)
            for c in await self._repo.commitments_for_user(user.usuario_id, estado)
        ]

    async def _update_commitment(
        self, user: CurrentUser, compromiso_id: int, body: s.CommitmentUpdate
    ) -> Compromiso:
        c = await self._repo.get_commitment(compromiso_id)
        if c is None:
            raise CommitmentNotFound
        if c.responsable_usuario_id != user.usuario_id and not user.can_staff(
            "asesorias:modificacion"
        ):
            raise Forbidden("Este compromiso no es tuyo.")
        moment = now()
        if body.completado:
            when = body.fecha or moment
            c.estado = "cumplido"
            c.fecha_completado = min(when, moment)
        else:
            c.estado = "pendiente"
            c.fecha_completado = None
        return c

    async def update_commitment(
        self, user: CurrentUser, compromiso_id: int, body: s.CommitmentUpdate
    ) -> s.CommitmentOut:
        c = await self._update_commitment(user, compromiso_id, body)
        await self._repo.commit()
        return self._commitment_out(c)

    # --- recomendaciones -----------------------------------------------------------

    @staticmethod
    def _recommendation_out(r: Recomendacion) -> s.RecommendationOut:
        return s.RecommendationOut(
            recomendacion_id=r.recomendacion_id,
            sesion_id=r.sesion_acompanamiento_id,
            titulo=r.titulo,
            contenido=r.contenido,
            estado=r.estado,
            fecha=r.fecha,
        )

    async def create_recommendation(
        self, user: CurrentUser, sesion_id: int, body: s.RecommendationCreate
    ) -> s.RecommendationOut:
        row = await self._load(sesion_id)
        me = await self._participant(user, sesion_id)
        if not (
            (me and me.rol_participante == MENTOR_ROLE)
            or user.can_staff("asesorias:registro")
        ):
            raise Forbidden("Solo el mentor puede dejar recomendaciones.")
        rec = Recomendacion(
            emprendimiento_id=row.emprendimiento_id,
            usuario_id=user.usuario_id,
            sesion_acompanamiento_id=sesion_id,
            titulo=body.titulo,
            contenido=body.contenido,
            estado="activa",
            fecha=now(),
        )
        await self._repo.add(rec)
        await self._repo.commit()
        return self._recommendation_out(rec)

    async def register_recommendation(
        self, user: CurrentUser, body: s.RecommendationRegister
    ) -> s.RecommendationOut:
        """Recomendacion para un emprendimiento, vinculable a una sesion suya (CU17)."""
        if not await self._ventures.exists(body.emprendimiento_id):
            raise DomainError("Emprendimiento inexistente.")
        await self._require_work_on(user, body.emprendimiento_id, "asesorias:registro")
        await self._session_of(body.sesion_id, body.emprendimiento_id)
        rec = Recomendacion(
            emprendimiento_id=body.emprendimiento_id,
            usuario_id=user.usuario_id,
            sesion_acompanamiento_id=body.sesion_id,
            titulo=body.titulo,
            contenido=body.contenido,
            estado="activa",
            fecha=now(),
        )
        await self._repo.add(rec)
        await self._repo.commit()
        return self._recommendation_out(rec)

    async def my_recommendations(self, user: CurrentUser) -> list[s.RecommendationOut]:
        ids = await self._entrepreneurs.venture_ids_of_user(user.usuario_id)
        return [
            self._recommendation_out(r)
            for r in await self._repo.recommendations_for_ventures(ids)
        ]

    # --- avances (seguimientos) -----------------------------------------------------

    @staticmethod
    def _progress_out(p: Seguimiento, created: bool = True) -> s.ProgressOut:
        return s.ProgressOut(
            seguimiento_id=p.seguimiento_id,
            emprendimiento_id=p.emprendimiento_id,
            usuario_id=p.usuario_id,
            observaciones=p.observaciones,
            porcentaje_avance=p.porcentaje_avance,
            fecha=p.fecha,
            referencia_cliente=p.referencia_cliente,
            creado=created,
        )

    async def _log_progress(
        self, user: CurrentUser, body: s.ProgressCreate
    ) -> s.ProgressOut:
        venture_id, ref = await self._venture_for(user, body.emprendimiento_id)
        if ref is None or venture_id not in ref.emprendimiento_ids:
            raise Forbidden("Solo un miembro del emprendimiento registra avances.")
        if body.referencia_cliente:
            existing = await self._repo.progress_by_ref(
                user.usuario_id, body.referencia_cliente
            )
            if existing is not None:
                return self._progress_out(existing, created=False)
        moment = now()
        when = min(body.fecha, moment) if body.fecha else moment
        if when.tzinfo is None:
            when = when.replace(tzinfo=UTC)
        row = Seguimiento(
            emprendimiento_id=venture_id,
            usuario_id=user.usuario_id,
            observaciones=body.observaciones,
            porcentaje_avance=body.porcentaje_avance,
            referencia_cliente=body.referencia_cliente,
            fecha=when,
            estado="registrado",
        )
        await self._repo.add(row)
        if await self._weekly_streak(user.usuario_id):
            await self._gamification.award_event(user.usuario_id, "log_streak")
        return self._progress_out(row)

    async def log_progress(
        self, user: CurrentUser, body: s.ProgressCreate
    ) -> s.ProgressOut:
        try:
            out = await self._log_progress(user, body)
            await self._repo.commit()
        except IntegrityError:  # misma referencia llegando en paralelo
            existing = await self._repo.progress_by_ref(
                user.usuario_id, body.referencia_cliente or ""
            )
            if existing is None:
                raise
            return self._progress_out(existing, created=False)
        return out

    async def _weekly_streak(self, usuario_id: int) -> bool:
        since = now() - timedelta(weeks=STREAK_WEEKS)
        weeks = {
            d.isocalendar()[:2]
            for d in await self._repo.progress_dates(usuario_id, since)
        }
        needed = {
            (now() - timedelta(weeks=i)).isocalendar()[:2] for i in range(STREAK_WEEKS)
        }
        return needed.issubset(weeks)

    async def list_progress(
        self, user: CurrentUser, emprendimiento_id: int | None, limit: int
    ) -> list[s.ProgressOut]:
        venture_id, _ = await self._venture_for(user, emprendimiento_id)
        return [
            self._progress_out(p)
            for p in await self._repo.progress_for_venture(venture_id, limit)
        ]

    async def sync(self, user: CurrentUser, body: s.SyncRequest) -> s.SyncResult:
        avances: list[s.ProgressOut] = []
        compromisos: list[s.CommitmentOut] = []
        errores: list[str] = []
        for item in body.avances:
            try:
                avances.append(await self.log_progress(user, item))
            except DomainError as exc:
                errores.append(
                    f"avance {item.referencia_cliente or '-'}: {exc.message}"
                )
        for change in body.compromisos:
            try:
                compromisos.append(
                    await self.update_commitment(
                        user,
                        change.compromiso_id,
                        s.CommitmentUpdate(
                            completado=change.completado, fecha=change.fecha
                        ),
                    )
                )
            except DomainError as exc:
                errores.append(f"compromiso {change.compromiso_id}: {exc.message}")
        return s.SyncResult(avances=avances, compromisos=compromisos, errores=errores)

    # --- asignaciones ---------------------------------------------------------------

    async def _assignment_out(self, rows: list[Asignacion]) -> list[s.AssignmentOut]:
        users = await self._users.names_by_ids(sorted({r.usuario_id for r in rows}))
        ventures = await self._ventures.names_by_ids(
            sorted({r.emprendimiento_id for r in rows})
        )
        return [
            s.AssignmentOut(
                asignacion_id=r.asignacion_id,
                usuario_id=r.usuario_id,
                usuario=users.get(r.usuario_id),
                emprendimiento_id=r.emprendimiento_id,
                emprendimiento=ventures.get(r.emprendimiento_id),
                tipo_asignacion=r.tipo_asignacion,
                estado=r.estado,
                fecha_inicio=r.fecha_inicio,
                fecha_fin=r.fecha_fin,
            )
            for r in rows
        ]

    async def create_assignment(
        self, actor: CurrentUser, body: s.AssignmentCreate
    ) -> s.AssignmentOut:
        """Asigna un asesor HABILITADO a un emprendimiento; no duplica asignaciones activas."""
        self._require_coordination(actor)
        await self._mentor(body.usuario_id)
        profile = await self._repo.profile(body.usuario_id)
        if profile is None or not profile.habilitado:
            raise MentorNotEnabled
        if not await self._ventures.exists(body.emprendimiento_id):
            raise DomainError("Emprendimiento inexistente.")
        if (
            await self._repo.active_assignment(body.usuario_id, body.emprendimiento_id)
            is not None
        ):
            raise AssignmentExists
        row = Asignacion(
            usuario_id=body.usuario_id,
            emprendimiento_id=body.emprendimiento_id,
            tipo_asignacion=body.tipo_asignacion,
            estado="activa",
            fecha_inicio=now(),
        )
        await self._repo.add(row)
        await self._audit.record(
            actor.usuario_id,
            "negocio.asignacion",
            (await self._users.names_by_ids([body.usuario_id])).get(body.usuario_id),
            tabla="asignaciones",
            id_registro=row.asignacion_id,
            despues={"emprendimiento_id": body.emprendimiento_id},
        )
        await self._repo.commit()
        return (await self._assignment_out([row]))[0]

    async def list_assignments(
        self, usuario_id: int | None, emprendimiento_id: int | None
    ) -> list[s.AssignmentOut]:
        rows = await self._repo.list_assignments(
            usuario_id=usuario_id, emprendimiento_id=emprendimiento_id
        )
        return await self._assignment_out(rows)

    async def end_assignment(
        self, actor: CurrentUser, asignacion_id: int
    ) -> s.AssignmentOut:
        self._require_coordination(actor)
        row = await self._repo.get_assignment(asignacion_id)
        if row is None:
            raise AssignmentNotFound
        row.estado = "finalizada"
        row.fecha_fin = now()
        await self._audit.record(
            actor.usuario_id,
            "negocio.asignacion_fin",
            None,
            tabla="asignaciones",
            id_registro=asignacion_id,
        )
        await self._repo.commit()
        return (await self._assignment_out([row]))[0]

    # --- historial del emprendimiento (CU19) -------------------------------------------

    async def history(
        self, user: CurrentUser, emprendimiento_id: int | None, orden: str = "asc"
    ) -> list[s.HistoryEvent]:
        """Sesiones, avances, hitos, recomendaciones, compromisos y cambios de etapa.

        Permisos por emprendimiento: un emprendedor ve el suyo, el personal con
        `seguimiento:consulta` los de todos y un asesor solo los que tiene asignados.
        """
        venture_id, _ = await self._venture_for(user, emprendimiento_id)
        if (
            user.rol == ADVISOR_ROLE
            and await self._repo.active_assignment(user.usuario_id, venture_id) is None
        ):
            raise NotAssigned
        events: list[s.HistoryEvent] = []

        for x in await self._sessions_out(
            await self._repo.sessions_of_ventures([venture_id], None, None)
        ):
            events.append(
                s.HistoryEvent(
                    tipo="sesion",
                    referencia_id=x.sesion_id,
                    fecha=x.fecha_realizada or x.fecha_programada,
                    titulo=x.tema or "Sesión de mentoría",
                    detalle=x.observaciones,
                    estado=x.estado,
                    autor=x.mentor,
                )
            )

        progress = await self._repo.progress_for_venture(venture_id, 500)
        recommendations = await self._repo.recommendations_for_ventures([venture_id])
        commitments = await self._repo.commitments_of_venture(venture_id)
        names = await self._users.names_by_ids(
            sorted(
                {p.usuario_id for p in progress}
                | {r.usuario_id for r in recommendations}
                | {c.registrado_por_usuario_id for c in commitments}
                | {c.responsable_usuario_id for c in commitments}
            )
        )
        for p in progress:
            events.append(
                s.HistoryEvent(
                    tipo="avance",
                    referencia_id=p.seguimiento_id,
                    fecha=p.fecha,
                    titulo="Avance registrado",
                    detalle=p.observaciones,
                    estado=None,
                    autor=names.get(p.usuario_id),
                )
            )
        for r in recommendations:
            events.append(
                s.HistoryEvent(
                    tipo="recomendacion",
                    referencia_id=r.recomendacion_id,
                    fecha=r.fecha,
                    titulo=r.titulo,
                    detalle=r.contenido,
                    estado=r.estado,
                    autor=names.get(r.usuario_id),
                )
            )
        for c in commitments:
            # Un compromiso no guarda cuando se creo: cuenta desde que se cumplio o vence.
            events.append(
                s.HistoryEvent(
                    tipo="compromiso",
                    referencia_id=c.compromiso_id,
                    fecha=c.fecha_completado or c.fecha_limite,
                    titulo=c.descripcion or "Compromiso",
                    detalle=f"Responsable: {names.get(c.responsable_usuario_id, '—')}",
                    estado=c.estado,
                    autor=names.get(c.registrado_por_usuario_id),
                )
            )
        for h in await self._ventures.list_milestones(user, venture_id):
            events.append(
                s.HistoryEvent(
                    tipo="hito",
                    referencia_id=h.hito_id,
                    fecha=h.fecha_cumplimiento or h.fecha_estimada,
                    titulo=h.titulo,
                    detalle=h.descripcion,
                    estado=h.estado,
                    autor=None,
                )
            )
        for step in await self._ventures.stage_history(user, venture_id):
            events.append(
                s.HistoryEvent(
                    tipo="etapa",
                    referencia_id=step.emprendimiento_etapa_id,
                    fecha=step.fecha_inicio,
                    titulo=f"Pasó a {step.etapa}",
                    detalle=step.observaciones,
                    estado=step.estado,
                    autor=None,
                )
            )

        dated = sorted(
            (e for e in events if e.fecha is not None),
            key=lambda e: e.fecha or datetime.min.replace(tzinfo=UTC),
            reverse=orden == "desc",
        )
        return dated + [e for e in events if e.fecha is None]
