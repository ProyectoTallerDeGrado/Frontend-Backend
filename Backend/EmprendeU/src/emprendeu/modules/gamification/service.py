"""Servicio de gamification: camino de retos, XP, niveles e insignias."""

from __future__ import annotations

from datetime import date, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import Forbidden
from emprendeu.modules.audit import AuditService
from emprendeu.modules.documents import DocumentService
from emprendeu.modules.entrepreneurs import EntrepreneurRef, EntrepreneurService
from emprendeu.modules.gamification import schemas as s
from emprendeu.modules.gamification.exceptions import (
    BadgeNotFound,
    ChallengeAlreadyCompleted,
    ChallengeCriteriaNotMet,
    ChallengeLocked,
    ChallengeNotFound,
    InvalidStage,
    NoVenture,
)
from emprendeu.modules.gamification.levels import (
    level_for,
    progress_for,
)
from emprendeu.modules.gamification.models import (
    EmprendedorInsignia,
    EmprendimientoReto,
    MovimientoXp,
    Reto,
)
from emprendeu.modules.gamification.repository import GamificationRepository, now
from emprendeu.modules.users import CurrentUser
from emprendeu.modules.ventures import VentureService

STREAK_DAYS = 7
HISTORY_LIMIT = 20
MIN_EVIDENCE_CHARS = 10

# Nombres de insignia (los siembra la migracion de catalogos).
FIRST_STEP = "Primer paso"
CONSTANCY = "Constancia"
VALIDATOR = "Validador"
LOG_STREAK = "Bitácora al día"
CONNECTOR = "Conector"
GRADUATE = "Graduado"


def longest_streak(days: set[date]) -> int:
    best = run = 0
    previous: date | None = None
    for day in sorted(days):
        run = run + 1 if previous and day - previous == timedelta(days=1) else 1
        best = max(best, run)
        previous = day
    return best


class GamificationService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = GamificationRepository(session)
        self._audit = AuditService(session)
        self._entrepreneurs = EntrepreneurService(session)
        self._ventures = VentureService(session)
        self._documents = DocumentService(session)

    # --- API publica para otros modulos --------------------------------------

    async def award_event(self, usuario_id: int, event: str) -> list[str]:
        """Evalua insignias ligadas a un evento externo. No hace commit.

        Eventos: `session_attended` (mentoring) y `log_streak` (mentoring).
        """
        ref = await self._entrepreneurs.ref_for_user(usuario_id)
        if ref is None:
            return []
        names: list[str] = []
        if event == "session_attended":
            names.append(CONNECTOR)
        elif event == "log_streak":
            names.append(LOG_STREAK)
        granted = []
        for name in names:
            if await self._grant(ref.emprendedor_id, name):
                granted.append(name)
        return granted

    async def is_challenge_completed(
        self, emprendimiento_id: int, reto_id: int
    ) -> bool:
        rows = await self._repo.venture_challenges(emprendimiento_id)
        row = rows.get(reto_id)
        return row is not None and row.estado == "completado"

    async def last_activity_by_venture(self) -> dict[int, object]:
        return await self._repo.last_completion_by_venture()  # type: ignore[return-value]

    # --- catalogo ------------------------------------------------------------

    async def _stage_names(self) -> dict[int, str]:
        return {e.etapa_id: e.nombre for e in await self._ventures.stage_catalog()}

    @staticmethod
    def _challenge_out(r: Reto, stages: dict[int, str]) -> s.ChallengeOut:
        return s.ChallengeOut(
            reto_id=r.reto_id,
            titulo=r.titulo,
            descripcion=r.descripcion,
            tipo=r.tipo,
            etapa_id=r.etapa_id,
            etapa=stages.get(r.etapa_id),
            orden=r.orden,
            xp_recompensa=r.xp_recompensa or 0,
            estado=r.estado,
            criterio_completado=r.criterio_completado,
            requiere_evidencia=bool(r.requiere_evidencia),
        )

    async def list_challenges(self) -> list[s.ChallengeOut]:
        stages = await self._stage_names()
        return [
            self._challenge_out(r, stages) for r in await self._repo.list_challenges()
        ]

    async def create_challenge(
        self, actor: CurrentUser, body: s.ChallengeCreate
    ) -> s.ChallengeOut:
        stages = await self._stage_names()
        if body.etapa_id not in stages:
            raise InvalidStage
        reto = Reto(
            titulo=body.titulo,
            descripcion=body.descripcion,
            tipo=body.tipo,
            etapa_id=body.etapa_id,
            orden=body.orden or (await self._repo.max_order()) + 1,
            xp_recompensa=body.xp_recompensa,
            criterio_completado=body.criterio_completado,
            requiere_evidencia=body.requiere_evidencia,
            estado="activo",
        )
        await self._repo.add(reto)
        await self._audit.record(
            actor.usuario_id,
            "config.reto",
            reto.titulo,
            tabla="retos",
            id_registro=reto.reto_id,
            despues={"accion": "crear"},
        )
        await self._repo.commit()
        return self._challenge_out(reto, stages)

    async def update_challenge(
        self, actor: CurrentUser, reto_id: int, body: s.ChallengeUpdate
    ) -> s.ChallengeOut:
        reto = await self._repo.get_challenge(reto_id)
        if reto is None:
            raise ChallengeNotFound
        changes = body.model_dump(exclude_unset=True, exclude_none=True)
        before = {k: getattr(reto, k) for k in changes}
        for key, value in changes.items():
            setattr(reto, key, value)
        await self._audit.record(
            actor.usuario_id,
            "config.reto",
            reto.titulo,
            tabla="retos",
            id_registro=reto_id,
            antes=before,
            despues=changes,
        )
        await self._repo.commit()
        return self._challenge_out(reto, await self._stage_names())

    async def list_badges(self) -> list[s.BadgeOut]:
        return [
            s.BadgeOut(
                insignia_id=b.insignia_id,
                nombre=b.nombre,
                criterio=b.criterio,
                xp_recompensa=b.xp_recompensa or 0,
                estado=b.estado,
            )
            for b in await self._repo.list_badges()
        ]

    async def update_badge(
        self, actor: CurrentUser, insignia_id: int, body: s.BadgeUpdate
    ) -> s.BadgeOut:
        badge = await self._repo.get_badge(insignia_id)
        if badge is None:
            raise BadgeNotFound
        changes = body.model_dump(exclude_unset=True, exclude_none=True)
        before = {k: getattr(badge, k) for k in changes}
        for key, value in changes.items():
            setattr(badge, key, value)
        await self._audit.record(
            actor.usuario_id,
            "config.insignia",
            badge.nombre,
            tabla="insignias",
            id_registro=insignia_id,
            antes=before,
            despues=changes,
        )
        await self._repo.commit()
        return s.BadgeOut(
            insignia_id=badge.insignia_id,
            nombre=badge.nombre,
            criterio=badge.criterio,
            xp_recompensa=badge.xp_recompensa or 0,
            estado=badge.estado,
        )

    # --- camino --------------------------------------------------------------

    async def _resolve_venture(
        self, user: CurrentUser, emprendimiento_id: int | None
    ) -> tuple[int, EntrepreneurRef | None]:
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if emprendimiento_id is None:
            if ref is None or ref.primary_venture_id is None:
                raise NoVenture
            return ref.primary_venture_id, ref
        is_member = ref is not None and emprendimiento_id in ref.emprendimiento_ids
        if not (is_member or user.can_staff("seguimiento:consulta")):
            raise Forbidden("No tienes acceso a este emprendimiento.")
        return emprendimiento_id, ref

    async def _venture_xp(self, emprendimiento_id: int) -> int:
        total = 0
        for eid in await self._entrepreneurs.entrepreneur_ids_of_venture(
            emprendimiento_id
        ):
            total += await self._repo.xp_total(eid)
        return total

    async def journey(
        self, user: CurrentUser, emprendimiento_id: int | None
    ) -> s.JourneyOut:
        venture_id, _ = await self._resolve_venture(user, emprendimiento_id)
        stages = await self._stage_names()
        retos = await self._repo.list_challenges(only_active=True)
        done = await self._repo.venture_challenges(venture_id)
        current_found = False
        items: list[s.JourneyChallenge] = []
        for r in retos:
            row = done.get(r.reto_id)
            if row is not None and row.estado == "completado":
                state = "cumplido"
            elif not current_found:
                state, current_found = "en_curso", True
            else:
                state = "bloqueado"
            items.append(
                s.JourneyChallenge(
                    reto_id=r.reto_id,
                    titulo=r.titulo,
                    descripcion=r.descripcion,
                    etapa_id=r.etapa_id,
                    etapa=stages.get(r.etapa_id),
                    orden=r.orden,
                    xp_recompensa=r.xp_recompensa or 0,
                    estado=state,  # type: ignore[arg-type]
                    fecha_completado=row.fecha_completado if row else None,
                    criterio_completado=r.criterio_completado,
                    requiere_evidencia=bool(r.requiere_evidencia),
                )
            )
        journey_stages: list[s.JourneyStage] = []
        for etapa in await self._ventures.stage_catalog():
            mine = [i for i in items if i.etapa_id == etapa.etapa_id]
            if not mine:
                continue
            if all(i.estado == "cumplido" for i in mine):
                st = "cumplida"
            elif any(i.estado == "en_curso" for i in mine) or any(
                i.estado == "cumplido" for i in mine
            ):
                st = "en_curso"
            else:
                st = "bloqueada"
            journey_stages.append(
                s.JourneyStage(etapa_id=etapa.etapa_id, nombre=etapa.nombre, estado=st)  # type: ignore[arg-type]
            )
        member_ids = await self._entrepreneurs.entrepreneur_ids_of_venture(venture_id)
        xp = await self._venture_xp(venture_id)
        target, progress = progress_for(xp)
        earned: dict[int, datetime | None] = {}
        movements: list[MovimientoXp] = []
        for eid in member_ids:
            for badge_id, when in (await self._repo.earned_badges(eid)).items():
                prev = earned.get(badge_id)
                if badge_id not in earned or (
                    when is not None and (prev is None or when < prev)
                ):
                    earned[badge_id] = when
            movements.extend(await self._repo.history(eid, HISTORY_LIMIT))
        movements.sort(key=lambda m: (m.fecha is not None, m.fecha), reverse=True)
        return s.JourneyOut(
            emprendimiento_id=venture_id,
            xp_total=xp,
            nivel=level_for(xp),
            xp_siguiente_nivel=target,
            xp_faltante=None if target is None else target - xp,
            progreso_pct=progress,
            etapas=journey_stages,
            retos=items,
            insignias=await self._badge_progress(earned),
            historial=[
                s.XpMovement(motivo=m.motivo, cantidad=m.cantidad or 0, fecha=m.fecha)
                for m in movements[:HISTORY_LIMIT]
            ],
        )

    async def _badge_progress(
        self, earned: dict[int, datetime | None]
    ) -> list[s.BadgeProgress]:
        return [
            s.BadgeProgress(
                insignia_id=b.insignia_id,
                nombre=b.nombre,
                criterio=b.criterio,
                xp_recompensa=b.xp_recompensa or 0,
                obtenida=b.insignia_id in earned,
                fecha_obtenida=earned.get(b.insignia_id),
            )
            for b in await self._repo.list_badges()
            if b.estado == "activa"
        ]

    async def _check_evidence(
        self, reto: Reto, venture_id: int, body: s.CompleteChallengeIn | None
    ) -> tuple[str | None, int | None]:
        """Verifica los criterios del reto (CU07) y devuelve la evidencia a guardar."""
        text = (body.evidencia_texto or None) if body else None
        document_id = body.documento_id if body else None
        if document_id is not None and not await self._documents.is_evidence_of(
            document_id, venture_id
        ):
            raise ChallengeCriteriaNotMet(
                "El documento no existe o no es de tu emprendimiento.",
                details={"faltante": "documento_id"},
            )
        if reto.requiere_evidencia and document_id is None:
            if text is None:
                raise ChallengeCriteriaNotMet(
                    "Este reto exige evidencia: un texto o un documento.",
                    details={"faltante": "evidencia"},
                )
            if len(text) < MIN_EVIDENCE_CHARS:
                raise ChallengeCriteriaNotMet(
                    f"Describe la evidencia con al menos {MIN_EVIDENCE_CHARS} caracteres.",
                    details={"faltante": "evidencia_texto"},
                )
        return text, document_id

    async def complete_challenge(
        self,
        user: CurrentUser,
        reto_id: int,
        emprendimiento_id: int | None,
        body: s.CompleteChallengeIn | None = None,
    ) -> s.CompletionOut:
        venture_id, ref = await self._resolve_venture(user, emprendimiento_id)
        if ref is None or venture_id not in ref.emprendimiento_ids:
            raise Forbidden("Solo un miembro del emprendimiento puede cumplir retos.")
        reto = await self._repo.get_challenge(reto_id)
        if reto is None or reto.estado != "activo":
            raise ChallengeNotFound
        done = await self._repo.venture_challenges(venture_id)
        row = done.get(reto_id)
        if row is not None and row.estado == "completado":
            raise ChallengeAlreadyCompleted
        # Solo el primer reto pendiente (orden) esta desbloqueado.
        for other in await self._repo.list_challenges(only_active=True):
            other_row = done.get(other.reto_id)
            if other_row is not None and other_row.estado == "completado":
                continue
            if other.reto_id != reto_id:
                raise ChallengeLocked
            break
        evidence_text, evidence_document = await self._check_evidence(
            reto, venture_id, body
        )

        before_xp = await self._repo.xp_total(ref.emprendedor_id)
        if row is None:
            row = EmprendimientoReto(
                emprendimiento_id=venture_id, reto_id=reto_id, fecha_asignacion=now()
            )
        row.estado = "completado"
        row.fecha_completado = now()
        row.evidencia_texto = evidence_text
        row.documento_id = evidence_document
        await self._repo.add(row)
        awarded = reto.xp_recompensa or 0
        await self._repo.add(
            MovimientoXp(
                emprendedor_id=ref.emprendedor_id,
                reto_id=reto_id,
                cantidad=awarded,
                motivo=f"Reto: {reto.titulo}",
                fecha=now(),
            )
        )
        new_badges = await self._badges_after_challenge(user, ref, venture_id)
        for name in new_badges:
            awarded += await self._badge_xp(name)
        after_xp = await self._repo.xp_total(ref.emprendedor_id)
        await self._repo.commit()
        return s.CompletionOut(
            reto_id=reto_id,
            xp_otorgado=awarded,
            xp_total=after_xp,
            nivel=level_for(after_xp),
            subio_de_nivel=level_for(after_xp) > level_for(before_xp),
            insignias_nuevas=new_badges,
        )

    # --- insignias -----------------------------------------------------------

    async def _badge_xp(self, name: str) -> int:
        for b in await self._repo.list_badges():
            if b.nombre == name:
                return b.xp_recompensa or 0
        return 0

    async def _grant(self, emprendedor_id: int, name: str) -> bool:
        earned = await self._repo.earned_badges(emprendedor_id)
        for badge in await self._repo.list_badges():
            if badge.nombre != name or badge.estado != "activa":
                continue
            if badge.insignia_id in earned:
                return False
            await self._repo.add(
                EmprendedorInsignia(
                    emprendedor_id=emprendedor_id,
                    insignia_id=badge.insignia_id,
                    fecha_obtenida=now(),
                )
            )
            if badge.xp_recompensa:
                await self._repo.add(
                    MovimientoXp(
                        emprendedor_id=emprendedor_id,
                        cantidad=badge.xp_recompensa,
                        motivo=f"Insignia «{badge.nombre}»",
                        fecha=now(),
                    )
                )
            return True
        return False

    async def _badges_after_challenge(
        self, user: CurrentUser, ref: EntrepreneurRef, venture_id: int
    ) -> list[str]:
        done = await self._repo.venture_challenges(venture_id)
        completed = {rid for rid, r in done.items() if r.estado == "completado"}
        active = await self._repo.list_challenges(only_active=True)
        granted: list[str] = []
        candidates: list[str] = []
        if completed:
            candidates.append(FIRST_STEP)
        validation = [r for r in active if r.tipo == "validacion"]
        if validation and all(r.reto_id in completed for r in validation):
            candidates.append(VALIDATOR)
        if active and all(r.reto_id in completed for r in active):
            candidates.append(GRADUATE)
        if await self._has_login_streak(user.usuario_id):
            candidates.append(CONSTANCY)
        for name in candidates:
            if await self._grant(ref.emprendedor_id, name):
                granted.append(name)
        return granted

    async def _has_login_streak(self, usuario_id: int) -> bool:
        return longest_streak(await self._audit.login_days(usuario_id)) >= STREAK_DAYS

    # --- perfil ----------------------------------------------------------------

    async def profile(self, user: CurrentUser) -> s.ProfileOut:
        ref = await self._entrepreneurs.ref_for_user(user.usuario_id)
        if ref is None:
            raise NoVenture
        if await self._has_login_streak(user.usuario_id):
            if await self._grant(ref.emprendedor_id, CONSTANCY):
                await self._repo.commit()
        xp = await self._repo.xp_total(ref.emprendedor_id)
        level = level_for(xp)
        target, progress = progress_for(xp)
        earned = await self._repo.earned_badges(ref.emprendedor_id)
        return s.ProfileOut(
            xp_total=xp,
            nivel=level,
            xp_siguiente_nivel=target,
            xp_faltante=None if target is None else target - xp,
            progreso_pct=progress,
            insignias=await self._badge_progress(earned),
            historial=[
                s.XpMovement(motivo=m.motivo, cantidad=m.cantidad or 0, fecha=m.fecha)
                for m in await self._repo.history(ref.emprendedor_id, HISTORY_LIMIT)
            ],
        )
