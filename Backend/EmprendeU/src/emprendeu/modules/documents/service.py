"""Servicio de documents: carga, consulta, descarga y borrado de archivos."""

from __future__ import annotations

from collections.abc import AsyncIterator
from datetime import UTC, datetime
from pathlib import Path

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import Forbidden
from emprendeu.modules.audit import AuditService
from emprendeu.modules.documents.exceptions import (
    DocumentNotFound,
    FileTypeNotAllowed,
    MilestoneMismatch,
)
from emprendeu.modules.documents.models import Documento
from emprendeu.modules.documents.repository import DocumentRepository
from emprendeu.modules.documents.schemas import DocumentOut
from emprendeu.modules.documents.storage import (
    ALLOWED_EXTENSIONS,
    LocalStorage,
    extension_of,
    safe_name,
)
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.mentoring import MentoringService
from emprendeu.modules.users import CurrentUser

# Un asesor sube y elimina documentos solo de los emprendimientos que tiene asignados.
ASSIGNED_ADVISOR_PERMISSIONS = {"emprendedores:registro", "emprendedores:modificacion"}


def _out(d: Documento) -> DocumentOut:
    return DocumentOut(
        documento_id=d.documento_id,
        nombre=d.nombre,
        tipo=d.tipo,
        usuario_id=d.usuario_id,
        emprendimiento_id=d.emprendimiento_id,
        hito_id=d.hito_id,
        fecha_subida=d.fecha_subida,
    )


class DocumentService:
    def __init__(
        self, session: AsyncSession, storage: LocalStorage | None = None
    ) -> None:
        self._repo = DocumentRepository(session)
        self._storage = storage or LocalStorage()
        self._audit = AuditService(session)
        self._entrepreneurs = EntrepreneurService(session)
        self._mentoring = MentoringService(session)

    async def _staff_may(
        self, user: CurrentUser, venture_id: int | None, permission: str
    ) -> bool:
        """Personal con el permiso, o asesor con el emprendimiento asignado."""
        if venture_id is None:
            return False
        if user.can_staff(permission):
            return True
        return (
            user.rol == "asesor"
            and permission in ASSIGNED_ADVISOR_PERMISSIONS
            and await self._mentoring.has_active_assignment(user.usuario_id, venture_id)
        )

    async def _can_access(
        self, user: CurrentUser, venture_id: int | None, permission: str
    ) -> bool:
        if venture_id is None:
            return False
        if await self._staff_may(user, venture_id, permission):
            return True
        return await self._entrepreneurs.is_member(user.usuario_id, venture_id)

    async def upload(
        self,
        user: CurrentUser,
        filename: str,
        content_type: str | None,
        chunks: AsyncIterator[bytes],
        emprendimiento_id: int | None,
        hito_id: int | None = None,
    ) -> DocumentOut:
        extension = extension_of(filename)
        if extension not in ALLOWED_EXTENSIONS:
            raise FileTypeNotAllowed(sorted(ALLOWED_EXTENSIONS))
        if emprendimiento_id is not None and not await self._can_access(
            user, emprendimiento_id, "emprendedores:registro"
        ):
            raise Forbidden("No tienes acceso a este emprendimiento.")
        if hito_id is not None and (
            emprendimiento_id is None
            or not await self._repo.milestone_belongs(hito_id, emprendimiento_id)
        ):
            raise MilestoneMismatch
        stored = await self._storage.save(chunks, extension)
        doc = Documento(
            nombre=safe_name(filename),
            ruta=stored,
            tipo=(content_type or "")[:60] or None,
            usuario_id=user.usuario_id,
            emprendimiento_id=emprendimiento_id,
            hito_id=hito_id,
            fecha_subida=datetime.now(UTC),
        )
        try:
            await self._repo.add(doc)
            await self._audit.record(
                user.usuario_id,
                "negocio.documento",
                doc.nombre,
                tabla="documentos",
                id_registro=doc.documento_id,
                despues={"accion": "subir"},
            )
            await self._repo.commit()
        except Exception:
            self._storage.delete(stored)
            raise
        return _out(doc)

    async def list(
        self,
        user: CurrentUser,
        emprendimiento_id: int | None,
        hito_id: int | None = None,
    ) -> list[DocumentOut]:
        if emprendimiento_id is not None:
            if not await self._can_access(
                user, emprendimiento_id, "emprendedores:consulta"
            ):
                raise Forbidden("No tienes acceso a este emprendimiento.")
            rows = await self._repo.list(
                venture_ids=None,
                venture_id=emprendimiento_id,
                usuario_id=None,
                hito_id=hito_id,
            )
        elif user.can_staff("emprendedores:consulta"):
            rows = await self._repo.list(
                venture_ids=None, venture_id=None, usuario_id=None, hito_id=hito_id
            )
        else:
            ids = await self._entrepreneurs.venture_ids_of_user(user.usuario_id)
            rows = await self._repo.list(
                venture_ids=ids, venture_id=None, usuario_id=None, hito_id=hito_id
            )
        return [_out(d) for d in rows]

    async def _get(
        self, user: CurrentUser, documento_id: int, permission: str
    ) -> Documento:
        doc = await self._repo.get(documento_id)
        if doc is None:
            raise DocumentNotFound
        if doc.usuario_id == user.usuario_id:
            return doc
        if not await self._can_access(user, doc.emprendimiento_id, permission):
            raise Forbidden("No tienes acceso a este documento.")
        return doc

    async def file_for_download(
        self, user: CurrentUser, documento_id: int
    ) -> tuple[Path, Documento]:
        doc = await self._get(user, documento_id, "emprendedores:consulta")
        path = self._storage.path_for(doc.ruta or "")
        if path is None or not path.is_file():
            raise DocumentNotFound
        return path, doc

    async def delete(self, user: CurrentUser, documento_id: int) -> None:
        doc = await self._get(user, documento_id, "emprendedores:modificacion")
        if doc.usuario_id != user.usuario_id and not await self._staff_may(
            user, doc.emprendimiento_id, "emprendedores:modificacion"
        ):
            raise Forbidden("Solo quien subio el archivo o el personal puede borrarlo.")
        stored = doc.ruta
        name = doc.nombre
        await self._repo.delete(doc)
        await self._audit.record(
            user.usuario_id,
            "negocio.documento",
            name,
            tabla="documentos",
            id_registro=documento_id,
            despues={"accion": "borrar"},
        )
        await self._repo.commit()
        if stored:
            self._storage.delete(stored)
