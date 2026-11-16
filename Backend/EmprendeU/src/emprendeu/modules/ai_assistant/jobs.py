"""Tarea programada: informe semanal de bienestar por correo.

Pensada para cron o un scheduler externo (una vez por semana):

    uv run python -m emprendeu.modules.ai_assistant.jobs
"""

import asyncio

import structlog

from emprendeu.core.config import get_settings
from emprendeu.core.logging import configure_logging
from emprendeu.core.mailer import EmailUnavailable, SmtpMailer
from emprendeu.db.session import get_engine, get_sessionmaker
from emprendeu.modules.ai_assistant.service import AssistantService


async def run_report() -> int:
    async with get_sessionmaker()() as session:
        return await AssistantService(session).weekly_report(SmtpMailer())


def main() -> int:
    configure_logging(get_settings().environment)
    log = structlog.get_logger("wellbeing.job")

    async def run() -> int:
        try:
            return await run_report()
        finally:
            await get_engine().dispose()

    try:
        sent = asyncio.run(run())
    except EmailUnavailable:
        # Sin SMTP configurado (o caido) no hay informe; no es un fallo del programa.
        log.warning("informe_no_enviado", motivo="correo no disponible")
        return 0
    log.info("informe_enviado", destinatarios=sent)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
