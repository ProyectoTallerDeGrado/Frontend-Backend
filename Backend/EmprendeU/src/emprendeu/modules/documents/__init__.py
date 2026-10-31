"""Modulo documents: archivos asociados a usuarios y emprendimientos.

El `router` lo importa `api/v1.py`.
"""

from emprendeu.modules.documents.models import Documento
from emprendeu.modules.documents.service import DocumentService

__all__ = ["DocumentService", "Documento"]
