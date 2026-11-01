"""Tarea programada: detecta riesgo de desercion y crea alertas.

Pensada para cron o un scheduler externo (una vez al dia):

    uv run python -m emprendeu.modules.alerts.jobs
"""

import asyncio

import structlog

from emprendeu.core.config import get_settings
from emprendeu.core.logging import configure_logging
from emprendeu.db.session import get_engine, get_sessionmaker
from emprendeu.modules.alerts.service import AlertService


async def run_evaluation() -> dict[str, int]:
    async with get_sessionmaker()() as session:
        result = await AlertService(session).evaluate(actor_id=None)
    return result.por_tipo


def main() -> int:
    configure_logging(get_settings().environment)
    log = structlog.get_logger("alerts.job")

    async def run() -> dict[str, int]:
        try:
            return await run_evaluation()
        finally:
            await get_engine().dispose()

    created = asyncio.run(run())
    log.info("evaluacion_completada", creadas=created)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
