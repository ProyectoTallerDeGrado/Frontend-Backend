"""HTTP de documents (prefijo /documents)."""

from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, Response, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.db.session import get_session
from emprendeu.modules.documents.schemas import DocumentOut
from emprendeu.modules.documents.service import DocumentService
from emprendeu.modules.documents.storage import CHUNK
from emprendeu.modules.users import CurrentUserDep

router = APIRouter(prefix="/documents", tags=["documents"])


def _svc(session: Annotated[AsyncSession, Depends(get_session)]) -> DocumentService:
    return DocumentService(session)


Svc = Annotated[DocumentService, Depends(_svc)]


async def _chunks(upload: UploadFile) -> AsyncIterator[bytes]:
    while chunk := await upload.read(CHUNK):
        yield chunk


@router.post("", response_model=DocumentOut, status_code=status.HTTP_201_CREATED)
async def upload_document(
    service: Svc,
    user: CurrentUserDep,
    file: Annotated[UploadFile, File()],
    emprendimiento_id: Annotated[int | None, Form()] = None,
    hito_id: Annotated[int | None, Form()] = None,
) -> DocumentOut:
    return await service.upload(
        user,
        file.filename or "archivo",
        file.content_type,
        _chunks(file),
        emprendimiento_id,
        hito_id,
    )


@router.get("", response_model=list[DocumentOut])
async def list_documents(
    service: Svc,
    user: CurrentUserDep,
    emprendimiento_id: int | None = None,
    hito_id: int | None = None,
) -> list[DocumentOut]:
    return await service.list(user, emprendimiento_id, hito_id)


@router.get("/{documento_id}/download")
async def download_document(
    documento_id: int, service: Svc, user: CurrentUserDep
) -> FileResponse:
    path, doc = await service.file_for_download(user, documento_id)
    return FileResponse(
        path, filename=doc.nombre, media_type=doc.tipo or "application/octet-stream"
    )


@router.delete("/{documento_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    documento_id: int, service: Svc, user: CurrentUserDep
) -> Response:
    await service.delete(user, documento_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
