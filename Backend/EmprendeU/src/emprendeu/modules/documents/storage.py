"""Almacenamiento de archivos en disco local.

Los archivos se guardan con un nombre generado (nunca el del cliente) dentro de
`UPLOAD_DIR`, para evitar colisiones y recorridos de directorio. Ademas de la
extension se comprueba que el contenido sea del formato que dice ser. Para pasar a un
almacen de objetos basta con reimplementar esta clase.
"""

from __future__ import annotations

import re
import uuid
from collections.abc import AsyncIterator
from pathlib import Path

from emprendeu.core.config import get_settings
from emprendeu.core.errors import PayloadTooLarge
from emprendeu.modules.documents.exceptions import FileTypeNotAllowed

ALLOWED_EXTENSIONS = {
    ".pdf", ".png", ".jpg", ".jpeg", ".webp", ".txt", ".csv",
    ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
}  # fmt: skip
CHUNK = 1024 * 256

# Primeros bytes de cada formato binario permitido. La extension la escribe quien sube
# el archivo; la firma dice que es de verdad.
_ZIP = (b"PK\x03\x04",)  # docx, xlsx y pptx son ZIP
_OLE = (b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1",)  # doc, xls y ppt antiguos
SIGNATURES: dict[str, tuple[bytes, ...]] = {
    ".pdf": (b"%PDF-",),
    ".png": (b"\x89PNG\r\n\x1a\n",),
    ".jpg": (b"\xff\xd8\xff",),
    ".jpeg": (b"\xff\xd8\xff",),
    ".webp": (b"RIFF",),
    ".docx": _ZIP,
    ".xlsx": _ZIP,
    ".pptx": _ZIP,
    ".doc": _OLE,
    ".xls": _OLE,
    ".ppt": _OLE,
}
SIGNATURE_BYTES = 12


def content_matches(extension: str, head: bytes) -> bool:
    """True si los primeros bytes corresponden al formato que dice la extension."""
    if extension == ".webp":
        return head[:4] == b"RIFF" and head[8:12] == b"WEBP"
    signatures = SIGNATURES.get(extension)
    if signatures is None:
        # Texto (.txt, .csv): no tiene firma, pero un binario renombrado trae bytes nulos.
        return b"\x00" not in head
    return head.startswith(signatures)


def safe_name(name: str) -> str:
    """Nombre para mostrar: sin rutas ni caracteres raros."""
    base = Path(name.replace("\\", "/")).name
    return re.sub(r"[^\w.\- ()]", "_", base).strip() or "archivo"


def extension_of(name: str) -> str:
    return Path(name).suffix.lower()


class LocalStorage:
    def __init__(self, root: str | None = None, max_mb: int | None = None) -> None:
        settings = get_settings()
        self.root = Path(root or settings.upload_dir).resolve()
        self.max_bytes = (max_mb or settings.max_upload_mb) * 1024 * 1024

    async def save(self, chunks: AsyncIterator[bytes], extension: str) -> str:
        """Guarda el flujo y devuelve la ruta relativa. Aborta si supera el limite."""
        self.root.mkdir(parents=True, exist_ok=True)
        stored = f"{uuid.uuid4().hex}{extension}"
        target = self.root / stored
        size = 0
        head = b""
        checked = False
        try:
            with target.open("wb") as fh:
                async for chunk in chunks:
                    size += len(chunk)
                    if size > self.max_bytes:
                        raise PayloadTooLarge(
                            "El archivo supera el tamano maximo permitido.",
                            details={"max_mb": self.max_bytes // (1024 * 1024)},
                        )
                    if not checked:
                        head += chunk[: SIGNATURE_BYTES - len(head)]
                        if len(head) >= SIGNATURE_BYTES:
                            self._check_content(extension, head)
                            checked = True
                    fh.write(chunk)
            if not checked:  # archivo mas corto que la firma
                self._check_content(extension, head)
        except BaseException:
            target.unlink(missing_ok=True)
            raise
        return stored

    @staticmethod
    def _check_content(extension: str, head: bytes) -> None:
        if not content_matches(extension, head):
            raise FileTypeNotAllowed(sorted(ALLOWED_EXTENSIONS))

    def path_for(self, stored: str) -> Path | None:
        """Ruta absoluta si queda dentro de la raiz; `None` si intenta escapar."""
        candidate = (self.root / stored).resolve()
        return candidate if candidate.is_relative_to(self.root) else None

    def delete(self, stored: str) -> None:
        path = self.path_for(stored)
        if path is not None:
            path.unlink(missing_ok=True)
