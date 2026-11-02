"""Esquemas de indicators."""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import BaseModel, StringConstraints

Name = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=160)
]


class IndicatorTypeCreate(BaseModel):
    nombre: Name
    descripcion: str | None = None
    tipo: Annotated[str | None, StringConstraints(max_length=60)] = "cuantitativo"
    unidad: Annotated[str | None, StringConstraints(max_length=50)] = None


class IndicatorTypeOut(BaseModel):
    tipo_indicador_id: int
    nombre: str
    descripcion: str | None
    tipo: str | None
    unidad: str | None


class ValueCreate(BaseModel):
    tipo_indicador_id: int
    valor: Decimal
    periodo: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=1, max_length=40)
    ]


class ValueOut(BaseModel):
    valor_indicador_id: int
    emprendimiento_id: int
    tipo_indicador_id: int
    indicador: str | None
    unidad: str | None
    valor: Decimal | None
    periodo: str | None
    fecha_registro: datetime | None


class UsersOverview(BaseModel):
    total: int
    habilitadas: int
    deshabilitadas: int
    por_rol: dict[str, int]


class ServiceStatus(BaseModel):
    nombre: str
    detalle: str
    estado: str  # operativo | degradado


class Overview(BaseModel):
    usuarios: UsersOverview
    acciones_auditadas: int
    emprendimientos_activos: int
    alertas_abiertas: int
    servicios: list[ServiceStatus]


# --- dashboard ejecutivo (CU14) y reportes (CU21) -------------------------------------


class StageCount(BaseModel):
    etapa_id: int
    etapa: str
    orden: int | None
    total: int


class SessionsBlock(BaseModel):
    programadas: int
    realizadas: int
    canceladas: int


class CommitmentsBlock(BaseModel):
    pendientes: int  # hoy
    vencidos: int  # hoy: pendientes con fecha limite vencida
    cumplidos_periodo: int  # cumplidos dentro del periodo


class AlertsBlock(BaseModel):
    abiertas: int
    revisadas: int
    atendidas: int
    descartadas: int
    por_tipo: dict[str, int]


class IndicatorSummary(BaseModel):
    tipo_indicador_id: int
    nombre: str
    unidad: str | None
    registros: int
    promedio: Decimal | None


class Dashboard(BaseModel):
    """Solo lectura: emprendimientos activos (de una etapa, si se filtra) en un periodo."""

    desde: date | None
    hasta: date | None
    etapa_id: int | None
    emprendimientos_total: int
    por_etapa: list[StageCount]
    sesiones: SessionsBlock
    compromisos: CommitmentsBlock
    avances: int
    alertas: AlertsBlock
    indicadores: list[IndicatorSummary]


ReportKind = Literal["resumen", "sesiones", "alertas", "indicadores"]


class ReportColumn(BaseModel):
    clave: str
    etiqueta: str


class ReportOut(BaseModel):
    tipo: ReportKind
    titulo: str
    columnas: list[ReportColumn]
    filas: list[dict[str, str | int | float | None]]
    total: int  # todas las filas del reporte
    truncado: bool  # la vista previa muestra solo las primeras
    desde: date | None
    hasta: date | None
    etapa_id: int | None
