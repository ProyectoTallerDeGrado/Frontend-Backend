"""Servicio de admision al programa (CU26).

No importa `users` ni `ventures` (ellos dependen de este modulo): la creacion de
la cuenta y del emprendimiento llega por `AccountProvisioner`, que arma el router
(ver `provisioning.py`).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Protocol

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import TooManyRequests
from emprendeu.core.pagination import PageParams
from emprendeu.core.ratelimit import SlidingWindowLimiter
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import schemas as s
from emprendeu.modules.entrepreneurs.exceptions import (
    AdmissionDecided,
    AdmissionIncomplete,
    AdmissionNotFound,
    ApplicationPending,
)
from emprendeu.modules.entrepreneurs.models import Postulacion
from emprendeu.modules.entrepreneurs.repository import AdmissionRepository

# Postulaciones publicas por IP y ventana (limitador en memoria, como el del login).
ADMISSION_MAX_PER_WINDOW = 5
ADMISSION_WINDOW_SECONDS = 3600

_limiter: SlidingWindowLimiter | None = None


def get_admission_limiter() -> SlidingWindowLimiter:
    global _limiter  # noqa: PLW0603
    if _limiter is None:
        _limiter = SlidingWindowLimiter(
            ADMISSION_MAX_PER_WINDOW, ADMISSION_WINDOW_SECONDS
        )
    return _limiter


@dataclass(frozen=True, slots=True)
class Provisioned:
    emprendedor_id: int
    emprendimiento_id: int
    temporary_password: str | None


class AccountProvisioner(Protocol):
    async def provision(self, actor_id: int, application: Postulacion) -> Provisioned:
        """Crea cuenta, emprendedor y emprendimiento SIN confirmar la transaccion."""
        ...


def _out(row: Postulacion) -> s.AdmissionOut:
    return s.AdmissionOut(
        postulacion_id=row.postulacion_id,
        nombre=row.nombre,
        apellido=row.apellido,
        email=row.email,
        telefono=row.telefono,
        documento_identidad=row.documento_identidad,
        nombre_emprendimiento=row.nombre_emprendimiento,
        descripcion_emprendimiento=row.descripcion_emprendimiento,
        sector=row.sector,
        estado=row.estado,
        fecha_postulacion=row.fecha_postulacion,
        fecha_decision=row.fecha_decision,
        observaciones_decision=row.observaciones_decision,
        decidido_por_id=row.decidido_por_usuario_id,
        emprendedor_id=row.emprendedor_id,
        emprendimiento_id=row.emprendimiento_id,
    )


class AdmissionService:
    def __init__(
        self,
        session: AsyncSession,
        provisioner: AccountProvisioner | None = None,
        limiter: SlidingWindowLimiter | None = None,
    ) -> None:
        self._repo = AdmissionRepository(session)
        self._audit = AuditService(session)
        self._provisioner = provisioner
        self._limiter = limiter

    async def submit(
        self, body: s.AdmissionCreate, ip: str | None
    ) -> s.AdmissionReceived:
        """Alta publica de una postulacion; limitada por IP."""
        key = ip or "-"
        if self._limiter is not None:
            if self._limiter.is_blocked(key):
                raise TooManyRequests(
                    "Demasiadas postulaciones. Intenta de nuevo mas tarde.",
                    details={"retry_after": self._limiter.retry_after(key)},
                )
            self._limiter.hit(key)
        if await self._repo.pending_email_exists(body.email):
            raise ApplicationPending
        row = Postulacion(
            nombre=body.nombre,
            apellido=body.apellido,
            email=body.email,
            telefono=body.telefono,
            documento_identidad=(
                " ".join(body.documento_identidad.split())
                if body.documento_identidad
                else None
            ),
            nombre_emprendimiento=body.nombre_emprendimiento,
            descripcion_emprendimiento=body.descripcion_emprendimiento,
            sector=body.sector,
            estado="pendiente",
        )
        try:
            await self._repo.add(row)
        except IntegrityError as exc:  # misma postulacion llegando en paralelo
            await self._repo.rollback()
            raise ApplicationPending from exc
        await self._repo.commit()
        return s.AdmissionReceived(postulacion_id=row.postulacion_id, estado=row.estado)

    async def list(
        self, params: PageParams, estado: str | None, q: str | None
    ) -> tuple[list[s.AdmissionOut], int]:
        rows, total = await self._repo.list(
            estado=estado, q=q, offset=params.offset, limit=params.page_size
        )
        return [_out(r) for r in rows], total

    async def get(self, postulacion_id: int) -> s.AdmissionOut:
        row = await self._repo.get(postulacion_id)
        if row is None:
            raise AdmissionNotFound
        return _out(row)

    async def decide(
        self, actor_id: int, postulacion_id: int, body: s.AdmissionDecision
    ) -> s.AdmissionDecided:
        """Admite, rechaza o mantiene pendiente. Admitida/rechazada es definitiva."""
        row = await self._repo.get(postulacion_id, lock=True)
        if row is None:
            raise AdmissionNotFound
        if row.estado != "pendiente":
            raise AdmissionDecided
        before = {"estado": row.estado}
        temporary: str | None = None
        if body.decision == "pendiente":
            # Sigue sin decision: solo se anota la observacion (el esquema no admite
            # fecha de decision mientras el estado es pendiente).
            row.observaciones_decision = body.observaciones
        elif body.decision == "rechazada":
            if not body.observaciones:
                raise AdmissionIncomplete(["observaciones"])
            row.estado = "rechazada"
            row.observaciones_decision = body.observaciones
            row.fecha_decision = datetime.now(UTC)
            row.decidido_por_usuario_id = actor_id
        else:
            if self._provisioner is None:  # pragma: no cover - error de cableado
                raise RuntimeError("Falta el aprovisionador de cuentas.")
            if not row.documento_identidad:
                raise AdmissionIncomplete(["documento_identidad"])
            try:
                created = await self._provisioner.provision(actor_id, row)
            except Exception:
                await self._repo.rollback()
                raise
            temporary = created.temporary_password
            row.estado = "admitida"
            row.observaciones_decision = body.observaciones
            row.fecha_decision = datetime.now(UTC)
            row.decidido_por_usuario_id = actor_id
            row.emprendedor_id = created.emprendedor_id
            row.emprendimiento_id = created.emprendimiento_id
        await self._audit.record(
            actor_id,
            "negocio.postulacion",
            f"{row.nombre} {row.apellido}",
            tabla="postulaciones",
            id_registro=postulacion_id,
            antes=before,
            despues={"estado": row.estado, "decision": body.decision},
        )
        await self._repo.commit()
        return s.AdmissionDecided(
            **_out(row).model_dump(), temporary_password=temporary
        )
