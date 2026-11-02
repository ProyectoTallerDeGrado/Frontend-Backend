"""Servicio de entrepreneurs. Es tambien la API publica del modulo."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import PageParams
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs.exceptions import (
    ApplicationDecided,
    ApplicationNotFound,
    ApplicationPending,
    DocumentAlreadyRegistered,
    EntrepreneurNotFound,
)
from emprendeu.modules.entrepreneurs.models import Emprendedor, Postulacion
from emprendeu.modules.entrepreneurs.repository import EntrepreneurRepository
from emprendeu.modules.entrepreneurs.schemas import (
    ApplicationCreate,
    ApplicationOut,
    EntrepreneurOut,
    VentureLink,
)


@dataclass(frozen=True, slots=True)
class EntrepreneurRef:
    """Datos minimos que otros modulos necesitan de un emprendedor."""

    emprendedor_id: int
    usuario_id: int
    emprendimiento_ids: tuple[int, ...]

    @property
    def primary_venture_id(self) -> int | None:
        return self.emprendimiento_ids[0] if self.emprendimiento_ids else None


@dataclass(frozen=True, slots=True)
class ApplicationRef:
    """Datos de una postulacion pendiente que necesita quien la admite."""

    postulacion_id: int
    nombre: str
    apellido: str
    email: str
    documento_identidad: str | None
    nombre_emprendimiento: str
    descripcion_emprendimiento: str | None
    sector: str | None


def _clean(value: str | None) -> str | None:
    return (value or "").strip() or None


class EntrepreneurService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = EntrepreneurRepository(session)
        self._audit = AuditService(session)

    # --- API para otros modulos -------------------------------------------

    async def create_profile(self, usuario_id: int) -> EntrepreneurRef:
        """Crea el perfil de emprendedor del usuario (idempotente)."""
        existing = await self._repo.get_by_user(usuario_id)
        if existing is None:
            existing = await self._repo.add(
                Emprendedor(usuario_id=usuario_id, estado="activo")
            )
        return await self._ref(existing)

    async def ref_for_entrepreneur(self, emprendedor_id: int) -> EntrepreneurRef | None:
        found = await self._repo.get(emprendedor_id)
        return await self._ref(found) if found else None

    async def set_document(self, usuario_id: int, documento: str | None) -> None:
        """Guarda el documento de identidad; no puede repetirse entre emprendedores."""
        found = await self._repo.get_by_user(usuario_id)
        if found is None:
            raise EntrepreneurNotFound
        clean = " ".join((documento or "").split()) or None
        if clean is not None and await self._repo.document_in_use(clean, usuario_id):
            raise DocumentAlreadyRegistered
        found.documento_identidad = clean
        try:
            await self._repo.add(found)
        except IntegrityError as exc:  # dos altas a la vez con el mismo documento
            await self._repo.rollback()
            raise DocumentAlreadyRegistered from exc

    async def summaries(
        self, emprendedor_ids: list[int]
    ) -> dict[int, tuple[str, str, str, str | None]]:
        """`{id: (nombre, apellido, correo, documento)}` para listados de otros modulos."""
        return await self._repo.summaries(emprendedor_ids)

    async def ensure_document_free(self, documento: str) -> None:
        if await self._repo.document_in_use(" ".join(documento.split())):
            raise DocumentAlreadyRegistered

    async def out_for_user(self, usuario_id: int) -> EntrepreneurOut:
        return await self.me(usuario_id)

    async def ref_for_user(self, usuario_id: int) -> EntrepreneurRef | None:
        found = await self._repo.get_by_user(usuario_id)
        return await self._ref(found) if found else None

    async def link_venture(
        self, emprendedor_id: int, emprendimiento_id: int, rol: str | None = "fundador"
    ) -> None:
        await self._repo.link(emprendedor_id, emprendimiento_id, rol)

    async def is_member(self, usuario_id: int, emprendimiento_id: int) -> bool:
        return emprendimiento_id in await self._repo.venture_ids_of_user(usuario_id)

    async def venture_ids_of_user(self, usuario_id: int) -> list[int]:
        return await self._repo.venture_ids_of_user(usuario_id)

    async def user_ids_of_venture(self, emprendimiento_id: int) -> list[int]:
        return await self._repo.user_ids_of_venture(emprendimiento_id)

    async def entrepreneur_ids_of_venture(self, emprendimiento_id: int) -> list[int]:
        return await self._repo.entrepreneur_ids_of_venture(emprendimiento_id)

    async def venture_ids_of_entrepreneur(self, emprendedor_id: int) -> list[int]:
        return await self._repo.venture_ids_of_entrepreneur(emprendedor_id)

    async def _ref(self, e: Emprendedor) -> EntrepreneurRef:
        ids = await self._repo.venture_ids_of_entrepreneur(e.emprendedor_id)
        return EntrepreneurRef(e.emprendedor_id, e.usuario_id, tuple(sorted(ids)))

    # --- uso propio (router) ---------------------------------------------

    async def _out(
        self,
        e: Emprendedor,
        identity: tuple[str, str, str] | None | bool = False,
    ) -> EntrepreneurOut:
        # `False` = no precargada: se consulta. Las listas la pasan ya resuelta.
        if identity is False:
            identity = await self._repo.identity(e.usuario_id)
        nombre, apellido, email = identity if identity else (None, None, None)
        return EntrepreneurOut(
            emprendedor_id=e.emprendedor_id,
            usuario_id=e.usuario_id,
            nombre=nombre,
            apellido=apellido,
            email=email,
            documento_identidad=e.documento_identidad,
            estado=e.estado,
            fecha_registro=e.fecha_registro,
            emprendimientos=[
                VentureLink(
                    emprendimiento_id=link.emprendimiento_id,
                    rol_en_emprendimiento=link.rol_en_emprendimiento,
                )
                for link in e.emprendimientos
            ],
        )

    async def list(
        self, params: PageParams, q: str | None
    ) -> tuple[list[EntrepreneurOut], int]:
        rows, total = await self._repo.list(
            q=q, offset=params.offset, limit=params.page_size
        )
        identities = await self._repo.identities([r.usuario_id for r in rows])
        return [await self._out(r, identities.get(r.usuario_id)) for r in rows], total

    async def get(self, emprendedor_id: int) -> EntrepreneurOut:
        found = await self._repo.get(emprendedor_id)
        if found is None:
            raise EntrepreneurNotFound
        return await self._out(found)

    async def me(self, usuario_id: int) -> EntrepreneurOut:
        found = await self._repo.get_by_user(usuario_id)
        if found is None:
            raise EntrepreneurNotFound
        return await self._out(found)

    async def update_me(
        self, usuario_id: int, documento: str | None
    ) -> EntrepreneurOut:
        await self.set_document(usuario_id, documento)
        return await self.me(usuario_id)

    # --- postulaciones (CU26) ---------------------------------------------------------

    async def submit_application(self, body: ApplicationCreate) -> None:
        """Alta publica. Una por correo mientras siga pendiente (409 si hay otra)."""
        if body.sitio_web.strip():  # campo trampa lleno: es un bot; se finge exito
            return
        if await self._repo.pending_application_by_email(body.email):
            raise ApplicationPending
        row = Postulacion(
            nombre=body.nombre,
            apellido=body.apellido,
            email=body.email,
            telefono=_clean(body.telefono),
            documento_identidad=_clean(body.documento_identidad),
            nombre_emprendimiento=body.nombre_emprendimiento,
            descripcion_emprendimiento=_clean(body.descripcion_emprendimiento),
            sector=_clean(body.sector),
            estado="pendiente",
        )
        try:
            await self._repo.add_application(row)
            await self._repo.commit()
        except IntegrityError as exc:  # dos envios a la vez con el mismo correo
            await self._repo.rollback()
            raise ApplicationPending from exc

    async def _application_out(self, row: Postulacion) -> ApplicationOut:
        decided_by = None
        if row.decidido_por_usuario_id is not None:
            identity = await self._repo.identity(row.decidido_por_usuario_id)
            decided_by = f"{identity[0]} {identity[1]}" if identity else None
        return ApplicationOut(
            postulacion_id=row.postulacion_id,
            nombre=row.nombre,
            apellido=row.apellido,
            email=row.email,
            telefono=row.telefono,
            documento_identidad=row.documento_identidad,
            nombre_emprendimiento=row.nombre_emprendimiento,
            descripcion_emprendimiento=row.descripcion_emprendimiento,
            sector=row.sector,
            fecha_postulacion=row.fecha_postulacion,
            estado=row.estado,
            fecha_decision=row.fecha_decision,
            observaciones_decision=row.observaciones_decision,
            decidido_por=decided_by,
            emprendedor_id=row.emprendedor_id,
            emprendimiento_id=row.emprendimiento_id,
        )

    async def list_applications(
        self, params: PageParams, estado: str | None, q: str | None
    ) -> tuple[list[ApplicationOut], int]:
        rows, total = await self._repo.list_applications(
            estado=estado, q=q, offset=params.offset, limit=params.page_size
        )
        return [await self._application_out(r) for r in rows], total

    async def get_application(self, postulacion_id: int) -> ApplicationOut:
        row = await self._repo.get_application(postulacion_id)
        if row is None:
            raise ApplicationNotFound
        return await self._application_out(row)

    async def _pending(self, postulacion_id: int) -> Postulacion:
        row = await self._repo.get_application(postulacion_id, lock=True)
        if row is None:
            raise ApplicationNotFound
        if row.estado != "pendiente":
            raise ApplicationDecided
        return row

    async def reject_application(
        self, actor_id: int, postulacion_id: int, observaciones: str
    ) -> ApplicationOut:
        row = await self._pending(postulacion_id)
        row.estado = "rechazada"
        row.fecha_decision = datetime.now(UTC)
        row.decidido_por_usuario_id = actor_id
        row.observaciones_decision = observaciones
        await self._audit.record(
            actor_id,
            "negocio.postulacion",
            f"{row.nombre} {row.apellido}",
            tabla="postulaciones",
            id_registro=postulacion_id,
            despues={"accion": "rechazar"},
        )
        await self._repo.commit()
        return await self._application_out(row)

    async def claim_application(self, postulacion_id: int) -> ApplicationRef:
        """Toma una postulacion pendiente (bloqueada) para admitirla. 409 si ya se decidio."""
        row = await self._pending(postulacion_id)
        return ApplicationRef(
            postulacion_id=row.postulacion_id,
            nombre=row.nombre,
            apellido=row.apellido,
            email=row.email,
            documento_identidad=row.documento_identidad,
            nombre_emprendimiento=row.nombre_emprendimiento,
            descripcion_emprendimiento=row.descripcion_emprendimiento,
            sector=row.sector,
        )

    async def mark_admitted(
        self,
        postulacion_id: int,
        *,
        emprendedor_id: int,
        emprendimiento_id: int,
        actor_id: int,
        observaciones: str | None,
    ) -> None:
        """Vincula la postulacion con lo creado. No hace commit: lo hace quien admite."""
        row = await self._pending(postulacion_id)
        row.estado = "admitida"
        row.fecha_decision = datetime.now(UTC)
        row.decidido_por_usuario_id = actor_id
        row.observaciones_decision = _clean(observaciones)
        row.emprendedor_id = emprendedor_id
        row.emprendimiento_id = emprendimiento_id
        await self._repo.add_application(row)
