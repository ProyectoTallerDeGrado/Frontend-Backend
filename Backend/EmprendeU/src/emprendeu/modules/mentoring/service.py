"""Servicio de mentoring: mentores, agenda, sesiones, compromisos y avances."""

from __future__ import annotations

from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.config import get_settings
from emprendeu.core.errors import DomainError, Forbidden
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurRef, EntrepreneurService
from emprendeu.modules.gamification import GamificationService
from emprendeu.modules.mentoring import schemas as s
from emprendeu.modules.mentoring.exceptions import (
    AssignmentNotFound,
    BookingNotEnabled,
    CommitmentNotFound,
    InvalidSlot,
    MentorLocked,
    MentorNotFound,
    NoVenture,
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
STREAK_WEEKS = 4


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
        mentors = await self._users.mentors()
        profiles = await self._repo.profiles()
        venture_id: int | None = None
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if emprendimiento_id is not None:
            venture_id = emprendimiento_id
        elif ref is not None:
            venture_id = ref.primary_venture_id
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
                    bloqueado=locked,
                    motivo_bloqueo=reason,
                )
            )
        return out

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
            profile = PerfilMentor(usuario_id=mentor_id)
        profile.especialidad = body.especialidad
        profile.reto_requerido_id = body.reto_requerido_id
        await self._repo.add(profile)
        await self._repo.commit()
        for m in await self.list_mentors(user, None):
            if m.usuario_id == mentor_id:
                return m
        raise MentorNotFound

    async def get_availability(self, mentor_id: int) -> list[s.AvailabilityItem]:
        await self._mentor(mentor_id)
        return [
            s.AvailabilityItem(
                dia_semana=a.dia_semana,
                hora_inicio=a.hora_inicio,
                duracion_min=a.duracion_min,
            )
            for a in await self._repo.availability(mentor_id)
        ]

    async def set_availability(
        self, user: CurrentUser, mentor_id: int, items: list[s.AvailabilityItem]
    ) -> list[s.AvailabilityItem]:
        if not self._can_manage_mentor(user, mentor_id):
            raise Forbidden("No puedes editar esta disponibilidad.")
        await self._mentor(mentor_id)
        unique = {(i.dia_semana, i.hora_inicio): i for i in items}
        await self._repo.replace_availability(
            mentor_id,
            [
                DisponibilidadMentor(
                    usuario_id=mentor_id,
                    dia_semana=i.dia_semana,
                    hora_inicio=i.hora_inicio,
                    duracion_min=i.duracion_min,
                )
                for i in unique.values()
            ],
        )
        await self._repo.commit()
        return await self.get_availability(mentor_id)

    async def slots(self, mentor_id: int, day: date) -> list[s.SlotOut]:
        await self._mentor(mentor_id)
        tz = _tz()
        rows = [
            a
            for a in await self._repo.availability(mentor_id)
            if a.dia_semana == day.weekday()
        ]
        start = datetime.combine(day, time(0), tz).astimezone(UTC)
        booked = await self._repo.mentor_sessions_between(
            mentor_id, start, start + timedelta(days=1)
        )
        moment = now()
        out: list[s.SlotOut] = []
        for a in rows:
            begin = datetime.combine(day, a.hora_inicio, tz).astimezone(UTC)
            end = begin + timedelta(minutes=a.duracion_min)
            busy = any(
                b.fecha_programada is not None and begin <= b.fecha_programada < end
                for b in booked
            )
            out.append(
                s.SlotOut(
                    inicio=begin,
                    hora=a.hora_inicio.strftime("%H:%M"),
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
        if profile and profile.reto_requerido_id:
            if not await self._gamification.is_challenge_completed(
                venture_id, profile.reto_requerido_id
            ):
                titles = await self._challenge_titles()
                raise MentorLocked(
                    "Se desbloquea al completar "
                    f"«{titles.get(profile.reto_requerido_id, 'un reto')}»"
                )
        start = body.inicio if body.inicio.tzinfo else body.inicio.replace(tzinfo=UTC)
        start = start.astimezone(UTC)
        local = start.astimezone(_tz())
        match = next(
            (
                a
                for a in await self._repo.availability(body.mentor_id)
                if a.dia_semana == local.weekday()
                and a.hora_inicio == local.time().replace(microsecond=0)
            ),
            None,
        )
        if match is None:
            raise InvalidSlot
        if start <= now():
            raise InvalidSlot
        busy = await self._repo.mentor_sessions_between(
            body.mentor_id, start, start + timedelta(minutes=match.duracion_min)
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
            tipo=SESSION_TYPE,
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

    async def my_sessions(
        self, user: CurrentUser, filtro: str | None
    ) -> list[s.SessionOut]:
        estados = {
            "proximas": ["programada"],
            "realizadas": ["realizada"],
            "canceladas": ["cancelada"],
        }.get(filtro or "")
        rows = await self._repo.sessions_for_user(user.usuario_id, estados)
        if filtro == "proximas":
            rows.sort(key=lambda r: r.fecha_programada or now())
        return await self._sessions_out(rows)

    async def list_sessions(
        self, offset: int, limit: int, estado: str | None
    ) -> tuple[list[s.SessionOut], int]:
        rows, total = await self._repo.list_sessions(
            estado=estado, offset=offset, limit=limit
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
        row.estado = "realizada"
        row.fecha_realizada = now()
        row.observaciones = body.observaciones
        for p in (await self._repo.participants([sesion_id]))[sesion_id]:
            if p.rol_participante == LEARNER_ROLE:
                await self._gamification.award_event(p.usuario_id, "session_attended")
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
            sesion_id=c.sesion_acompanamiento_id,
            descripcion=c.descripcion,
            estado=c.estado,
            fecha_limite=c.fecha_limite,
            fecha_completado=c.fecha_completado,
        )

    async def create_commitment(
        self, user: CurrentUser, sesion_id: int, body: s.CommitmentCreate
    ) -> s.CommitmentOut:
        await self._load(sesion_id)
        me = await self._participant(user, sesion_id)
        if not (
            (me and me.rol_participante == MENTOR_ROLE)
            or user.can_staff("asesorias:registro")
        ):
            raise Forbidden("Solo el mentor puede asignar compromisos.")
        parts = (await self._repo.participants([sesion_id]))[sesion_id]
        learners = [p.usuario_id for p in parts if p.rol_participante == LEARNER_ROLE]
        responsible = body.usuario_id or (learners[0] if learners else None)
        if responsible is None or responsible not in {p.usuario_id for p in parts}:
            raise DomainError("El responsable debe participar en la sesion.")
        names = await self._users.names_by_ids([responsible])
        commitment = Compromiso(
            sesion_acompanamiento_id=sesion_id,
            usuario_id=responsible,
            responsable_usuario=names.get(responsible),
            descripcion=body.descripcion,
            fecha_limite=body.fecha_limite,
            estado="pendiente",
        )
        await self._repo.add(commitment)
        await self._repo.commit()
        return self._commitment_out(commitment)

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
        if c.usuario_id != user.usuario_id and not user.can_staff(
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
        await self._mentor(body.usuario_id)
        if not await self._ventures.exists(body.emprendimiento_id):
            raise DomainError("Emprendimiento inexistente.")
        row = Asignacion(
            usuario_id=body.usuario_id,
            emprendimiento_id=body.emprendimiento_id,
            tipo_asignacion=body.tipo_asignacion,
            estado="activa",
            fecha_inicio=now(),
        )
        await self._repo.add(row)
        await self._repo.commit()
        return (await self._assignment_out([row]))[0]

    async def list_assignments(
        self, usuario_id: int | None, emprendimiento_id: int | None
    ) -> list[s.AssignmentOut]:
        rows = await self._repo.list_assignments(
            usuario_id=usuario_id, emprendimiento_id=emprendimiento_id
        )
        return await self._assignment_out(rows)

    async def end_assignment(self, asignacion_id: int) -> s.AssignmentOut:
        row = await self._repo.get_assignment(asignacion_id)
        if row is None:
            raise AssignmentNotFound
        row.estado = "finalizada"
        row.fecha_fin = now()
        await self._repo.commit()
        return (await self._assignment_out([row]))[0]
