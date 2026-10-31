"""Almacenamiento de archivos en disco local.

Los archivos se guardan con un nombre generado (nunca el del cliente) dentro de
`UPLOAD_DIR`, para evitar colisiones y recorridos de directorio. Para pasar a un
almacen de objetos basta con reimplementar esta clase.
"""

from __future__ import annotations

import re
import uuid
from collections.abc import AsyncIterator
from pathlib import Path

from emprendeu.core.config import get_settings
from emprendeu.core.errors import PayloadTooLarge

ALLOWED_EXTENSIONS = {
    ".pdf", ".png", ".jpg", ".jpeg", ".webp", ".txt", ".csv",
    ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
}  # fmt: skip
CHUNK = 1024 * 256


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
        try:
            with target.open("wb") as fh:
                async for chunk in chunks:
                    size += len(chunk)
                    if size > self.max_bytes:
                        raise PayloadTooLarge(
                            "El archivo supera el tamano maximo permitido.",
                            details={"max_mb": self.max_bytes // (1024 * 1024)},
                        )
                    fh.write(chunk)
        except BaseException:
            target.unlink(missing_ok=True)
            raise
        return stored

    def path_for(self, stored: str) -> Path | None:
        """Ruta absoluta si queda dentro de la raiz; `None` si intenta escapar."""
        candidate = (self.root / stored).resolve()
        return candidate if candidate.is_relative_to(self.root) else None

    def delete(self, stored: str) -> None:
        path = self.path_for(stored)
        if path is not None:
            path.unlink(missing_ok=True)
