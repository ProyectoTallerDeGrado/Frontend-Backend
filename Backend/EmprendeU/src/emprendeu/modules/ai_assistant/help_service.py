"""Asistente de ayuda del panel web: responde como usar el sistema.

Independiente del coach (`service.py`): no guarda conversaciones ni analiza el animo.
Usa Gemini con la guia (`help_guide.py`) filtrada por el rol de quien pregunta y,
si no hay clave, se agoto la cuota diaria o Gemini falla, contesta con la guia sin IA.
"""

from __future__ import annotations

from datetime import UTC, datetime

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.config import get_settings
from emprendeu.modules.ai_assistant import help_guide
from emprendeu.modules.ai_assistant.exceptions import AIUnavailable
from emprendeu.modules.ai_assistant.gemini import HelpLLM
from emprendeu.modules.ai_assistant.repository import HelpUsageRepository
from emprendeu.modules.ai_assistant.schemas import HelpReply, HelpRequest
from emprendeu.modules.users import CurrentUser

MAX_HISTORY = 6

SYSTEM_PROMPT = """Eres el asistente de ayuda de EmprendeU, el panel web del Centro de \
Innovacion y Emprendimiento Universitario (CIE-U).
Tu unica tarea es explicar COMO USAR EL SISTEMA: donde esta cada pantalla, que se puede \
hacer en ella y los pasos para lograrlo.
Reglas:
- Responde en espanol, con tono cercano y breve (maximo 6 frases o una lista corta de pasos).
- Usa SOLO la guia de abajo. Si algo no esta en la guia, dilo y sugiere a quien acudir \
(un administrador del CIE-U). No inventes pantallas, botones ni datos.
- Quien pregunta tiene el rol {role}: solo menciona pantallas de su guia. Si pide algo que \
su rol no puede hacer, explicale que necesita que un administrador le de el permiso.
- Esta ahora en la pantalla {route}; si la pregunta es ambigua, asume que habla de ella.
- No respondas temas ajenos al uso del sistema (tareas, programacion, opiniones): \
redirige con amabilidad.
- Puedes usar **negritas** y listas numeradas en Markdown simple.

GUIA DEL SISTEMA PARA ESTE ROL:
{guide}
"""


class HelpService:
    def __init__(self, session: AsyncSession, llm: HelpLLM) -> None:
        self._usage = HelpUsageRepository(session)
        self._llm = llm
        self._limit = get_settings().help_daily_limit

    async def answer(self, user: CurrentUser, body: HelpRequest) -> HelpReply:
        role = user.rol
        route = body.ruta or "desconocida"
        today = datetime.now(UTC).date()

        def faq() -> HelpReply:
            return HelpReply(
                respuesta=help_guide.faq_answer(body.mensaje, role, body.ruta),
                origen="guia",
                restantes_hoy=None,
            )

        if not self._llm.configured:
            return faq()
        used = await self._usage.reserve_call(today, self._limit)
        if used is None:
            return faq()
        system = SYSTEM_PROMPT.format(
            role=help_guide.ROLE_LABELS.get(role or "", role or "sin rol"),
            route=route,
            guide=help_guide.guide_for(role),
        )
        history = [(t.rol, t.texto) for t in body.historial[-MAX_HISTORY:]]
        try:
            text = await self._llm.chat(system, body.mensaje, history)
        except AIUnavailable:
            structlog.get_logger("ai.help").warning("gemini_no_disponible")
            await self._usage.release_call(today)
            return faq()
        return HelpReply(
            respuesta=text, origen="ia", restantes_hoy=max(self._limit - used, 0)
        )
