"""Dependencias del modulo audit."""

from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.db.session import get_session
from emprendeu.modules.audit.service import AuditService


def get_audit_service(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> AuditService:
    return AuditService(session)


AuditServiceDep = Annotated[AuditService, Depends(get_audit_service)]
