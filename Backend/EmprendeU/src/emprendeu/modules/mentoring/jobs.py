"""Tarea programada: recordatorios de mentorias y compromisos (push + bandeja).

Pensada para cron o un scheduler externo, cada hora por ejemplo:

    uv run python -m emprendeu.modules.mentoring.jobs

Un mismo recordatorio no se repite aunque la tarea corra varias veces.
"""

import asyncio

import structlog

from emprendeu.core.config import get_settings
from emprendeu.core.logging import configure_logging
from emprendeu.db.session import get_engine, get_sessionmaker
from emprendeu.modules.mentoring.service import MentoringService
from emprendeu.modules.notifications import wait_for_pushes


async def run_reminders() -> tuple[int, int]:
    async with get_sessionmaker()() as session:
        result = await MentoringService(session).send_reminders()
    # Los push salen en segundo plano tras el commit: hay que esperarlos.
    await wait_for_pushes()
    return result


def main() -> int:
    configure_logging(get_settings().environment)
    log = structlog.get_logger("mentoring.reminders")

    async def run() -> tuple[int, int]:
        try:
            return await run_reminders()
        finally:
            await get_engine().dispose()

    sessions, commitments = asyncio.run(run())
    log.info("recordatorios_enviados", sesiones=sessions, compromisos=commitments)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
