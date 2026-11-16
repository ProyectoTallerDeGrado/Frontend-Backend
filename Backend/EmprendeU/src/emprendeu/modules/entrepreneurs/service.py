"""Servicio de entrepreneurs. Es tambien la API publica del modulo."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.pagination import PageParams
from emprendeu.modules.entrepreneurs.exceptions import (
    DocumentAlreadyRegistered,
    EntrepreneurNotFound,
)
from emprendeu.modules.entrepreneurs.models import Emprendedor
from emprendeu.modules.entrepreneurs.repository import EntrepreneurRepository
from emprendeu.modules.entrepreneurs.schemas import EntrepreneurOut, VentureLink


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
class MemberRef:
    """Un integrante de un emprendimiento, con su rol dentro del equipo."""

    emprendimiento_id: int
    emprendedor_id: int
    usuario_id: int
    nombre: str | None
    apellido: str | None
    email: str | None
    rol_en_emprendimiento: str | None
    fecha_ingreso: datetime | None


class EntrepreneurService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = EntrepreneurRepository(session)

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
        await self._repo.add(found)

    async def ensure_document_free(self, documento: str) -> None:
        if await self._repo.document_in_use(" ".join(documento.split())):
            raise DocumentAlreadyRegistered

    async def out_for_user(self, usuario_id: int) -> EntrepreneurOut:
        return await self.me(usuario_id)

    async def ref_for_user(self, usuario_id: int) -> EntrepreneurRef | None:
        found = await self._repo.get_by_user(usuario_id)
        return await self._ref(found) if found else None

    async def names_by_entrepreneur(self, emprendedor_ids: list[int]) -> dict[int, str]:
        """Nombre completo por `emprendedor_id` (para listas de otros modulos)."""
        return await self._repo.names_by_entrepreneur(emprendedor_ids)

    async def link_venture(
        self, emprendedor_id: int, emprendimiento_id: int, rol: str | None = "fundador"
    ) -> bool:
        """Vincula al emprendedor. Falso si ya era integrante (no duplica)."""
        return await self._repo.link(emprendedor_id, emprendimiento_id, rol)

    async def set_member_role(
        self, emprendedor_id: int, emprendimiento_id: int, rol: str | None
    ) -> bool:
        """Cambia el rol dentro del equipo. Falso si no era integrante."""
        return await self._repo.set_role(emprendedor_id, emprendimiento_id, rol)

    async def unlink_venture(self, emprendedor_id: int, emprendimiento_id: int) -> bool:
        """Quita al emprendedor del emprendimiento. Falso si no era integrante."""
        return await self._repo.unlink(emprendedor_id, emprendimiento_id)

    async def members_of_ventures(
        self, emprendimiento_ids: list[int]
    ) -> dict[int, list[MemberRef]]:
        """Integrantes de cada emprendimiento, en orden de ingreso."""
        rows = await self._repo.members_of_ventures(emprendimiento_ids)
        identities = await self._repo.identities(list({e.usuario_id for _, e in rows}))
        out: dict[int, list[MemberRef]] = {i: [] for i in emprendimiento_ids}
        for link, e in rows:
            nombre, apellido, email = identities.get(e.usuario_id, (None, None, None))
            out.setdefault(link.emprendimiento_id, []).append(
                MemberRef(
                    emprendimiento_id=link.emprendimiento_id,
                    emprendedor_id=e.emprendedor_id,
                    usuario_id=e.usuario_id,
                    nombre=nombre,
                    apellido=apellido,
                    email=email,
                    rol_en_emprendimiento=link.rol_en_emprendimiento,
                    fecha_ingreso=link.fecha_ingreso,
                )
            )
        return out

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
