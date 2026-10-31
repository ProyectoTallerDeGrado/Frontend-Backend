"""Esquemas de indicators."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Annotated

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
