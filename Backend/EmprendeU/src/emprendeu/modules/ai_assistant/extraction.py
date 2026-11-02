"""Extraccion de texto de los archivos que se suben a la base de conocimiento."""

from __future__ import annotations

from io import BytesIO
from pathlib import PurePath

from emprendeu.modules.ai_assistant.exceptions import (
    KnowledgeFileNotAllowed,
    KnowledgeFileUnreadable,
)

ALLOWED_EXTENSIONS = (".txt", ".md", ".pdf", ".docx")


def _plain(data: bytes) -> str:
    try:
        return data.decode("utf-8-sig")
    except UnicodeDecodeError:
        return data.decode("latin-1", errors="replace")


def _pdf(data: bytes) -> str:
    from pypdf import PdfReader

    reader = PdfReader(BytesIO(data))
    return "\n\n".join((page.extract_text() or "").strip() for page in reader.pages)


def _docx(data: bytes) -> str:
    from docx import Document

    document = Document(BytesIO(data))
    return "\n\n".join(p.text.strip() for p in document.paragraphs if p.text.strip())


def extract_text(filename: str, data: bytes) -> str:
    """Texto plano del archivo, segun su extension. Un archivo danado da 422."""
    extension = PurePath(filename).suffix.lower()
    if extension not in ALLOWED_EXTENSIONS:
        raise KnowledgeFileNotAllowed(list(ALLOWED_EXTENSIONS))
    try:
        if extension == ".pdf":
            return _pdf(data)
        if extension == ".docx":
            return _docx(data)
        return _plain(data)
    except KnowledgeFileUnreadable:
        raise
    except Exception as exc:  # pypdf/python-docx lanzan tipos muy variados
        raise KnowledgeFileUnreadable from exc
