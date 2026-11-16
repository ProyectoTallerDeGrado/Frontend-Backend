"""Puente coach -> alertas: avisa al personal cuando un mensaje muestra riesgo.

`alerts` depende de `ai_assistant` y no al reves: por eso el servicio del coach solo
conoce el protocolo `RiskNotifier`, y esta implementacion la importa unicamente el
router (el mismo recurso que `entrepreneurs/provisioning.py`).
"""

from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.alerts import AlertService


class AlertRiskNotifier:
    def __init__(self, session: AsyncSession) -> None:
        self._alerts = AlertService(session)

    async def notify(self, emprendedor_id: int) -> None:
        await self._alerts.raise_wellbeing_risk(emprendedor_id)
