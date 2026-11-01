"""Modulo audit: bitacora de acciones sensibles.

API publica: `AuditService.record(...)` (lo usan los demas modulos) y `router`.
"""

from emprendeu.modules.audit.models import Bitacora
from emprendeu.modules.audit.service import AuditService

__all__ = ["AuditService", "Bitacora"]
