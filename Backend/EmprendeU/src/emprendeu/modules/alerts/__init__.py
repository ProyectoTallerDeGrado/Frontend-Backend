"""Modulo alerts: parametros de seguimiento, deteccion de riesgo y alertas.

API publica: `AlertService` (`open_count`, `evaluate`). El `router` lo importa
`api/v1.py` y la tarea programada vive en `jobs.py`.
"""

from emprendeu.modules.alerts.models import Alerta, ParametroSeguimiento, TipoAlerta
from emprendeu.modules.alerts.service import AlertService

__all__ = ["AlertService", "Alerta", "ParametroSeguimiento", "TipoAlerta"]
