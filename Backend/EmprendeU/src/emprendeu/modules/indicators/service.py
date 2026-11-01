"""Servicio de indicators: catalogo, valores por emprendimiento y resumen del panel."""

from __future__ import annotations

from datetime import UTC, datetime

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.errors import Forbidden, NotFoundError
from emprendeu.modules.ai_assistant import AssistantService, LLMClient
from emprendeu.modules.alerts import AlertService
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.indicators import schemas as s
from emprendeu.modules.indicators.exceptions import IndicatorTypeNotFound
from emprendeu.modules.indicators.models import TipoIndicador, ValorIndicador
from emprendeu.modules.indicators.repository import IndicatorRepository
from emprendeu.modules.users import CurrentUser, build_user_service
from emprendeu.modules.ventures import VentureService


def _type_out(t: TipoIndicador) -> s.IndicatorTypeOut:
    return s.IndicatorTypeOut(
        tipo_indicador_id=t.tipo_indicador_id,
        nombre=t.nombre,
        descripcion=t.descripcion,
        tipo=t.tipo,
        unidad=t.unidad,
    )


class IndicatorService:
    def __init__(self, session: AsyncSession, llm: LLMClient) -> None:
        self._session = session
        self._llm = llm
        self._repo = IndicatorRepository(session)
        self._entrepreneurs = EntrepreneurService(session)
        self._ventures = VentureService(session)

    async def list_types(self) -> list[s.IndicatorTypeOut]:
        return [_type_out(t) for t in await self._repo.list_types()]

    async def create_type(self, body: s.IndicatorTypeCreate) -> s.IndicatorTypeOut:
        row = TipoIndicador(
            nombre=body.nombre,
            descripcion=body.descripcion,
            tipo=body.tipo,
            unidad=body.unidad,
        )
        await self._repo.add(row)
        await self._repo.commit()
        return _type_out(row)

    async def _access(
        self, user: CurrentUser, venture_id: int, permission: str
    ) -> None:
        if user.can_staff(permission):
            return
        if await self._entrepreneurs.is_member(user.usuario_id, venture_id):
            return
        raise Forbidden("No tienes acceso a este emprendimiento.")

    async def add_value(
        self, user: CurrentUser, venture_id: int, body: s.ValueCreate
    ) -> s.ValueOut:
        await self._access(user, venture_id, "reportes:registro")
        if not await self._ventures.exists(venture_id):
            raise NotFoundError("Emprendimiento no encontrado.")
        kind = await self._repo.get_type(body.tipo_indicador_id)
        if kind is None:
            raise IndicatorTypeNotFound
        row = ValorIndicador(
            emprendimiento_id=venture_id,
            tipo_indicador_id=kind.tipo_indicador_id,
            valor=body.valor,
            periodo=body.periodo,
            fecha_registro=datetime.now(UTC),
        )
        await self._repo.add(row)
        await self._repo.commit()
        return self._value_out(row, kind)

    @staticmethod
    def _value_out(v: ValorIndicador, t: TipoIndicador) -> s.ValueOut:
        return s.ValueOut(
            valor_indicador_id=v.valor_indicador_id,
            emprendimiento_id=v.emprendimiento_id,
            tipo_indicador_id=v.tipo_indicador_id,
            indicador=t.nombre,
            unidad=t.unidad,
            valor=v.valor,
            periodo=v.periodo,
            fecha_registro=v.fecha_registro,
        )

    async def list_values(self, user: CurrentUser, venture_id: int) -> list[s.ValueOut]:
        await self._access(user, venture_id, "reportes:consulta")
        return [self._value_out(v, t) for v, t in await self._repo.values(venture_id)]

    async def overview(self) -> s.Overview:
        users = await build_user_service(self._session).stats()
        by_role = {
            k.removeprefix("rol:"): v for k, v in users.items() if k.startswith("rol:")
        }
        audit_total = await AuditService(self._session).total()
        ai = await AssistantService(self._session, self._llm).status()
        await self._session.execute(text("SELECT 1"))
        return s.Overview(
            usuarios=s.UsersOverview(
                total=users["total"],
                habilitadas=users["habilitadas"],
                deshabilitadas=users["deshabilitadas"],
                por_rol=by_role,
            ),
            acciones_auditadas=audit_total,
            emprendimientos_activos=len(await self._ventures.active_venture_ids()),
            alertas_abiertas=await AlertService(self._session).open_count(),
            servicios=[
                s.ServiceStatus(
                    nombre="API REST (FastAPI)",
                    detalle="Autenticación y lógica de negocio",
                    estado="operativo",
                ),
                s.ServiceStatus(
                    nombre="PostgreSQL",
                    detalle="Base de datos central",
                    estado="operativo",
                ),
                s.ServiceStatus(
                    nombre="Motor de IA (Ollama + RAG)",
                    detalle=f"{ai.documentos_activos} documento(s) de conocimiento activos",
                    estado="operativo" if ai.ollama_disponible else "degradado",
                ),
                s.ServiceStatus(
                    nombre="Sincronización móvil",
                    detalle="Registros guardados sin conexion",
                    estado="operativo",
                ),
            ],
        )
