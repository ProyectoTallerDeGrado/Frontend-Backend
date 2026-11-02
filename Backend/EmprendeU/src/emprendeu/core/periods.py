"""Periodos por dias locales de la agenda, convertidos a instantes UTC."""

from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from emprendeu.core.config import get_settings


def _tz() -> ZoneInfo:
    return ZoneInfo(get_settings().app_timezone)


def period_bounds(
    desde: date | None, hasta: date | None
) -> tuple[datetime | None, datetime | None]:
    """`[inicio, fin)` en UTC de los dias locales `desde`..`hasta` (ambos inclusive)."""
    tz = _tz()
    start = datetime.combine(desde, time(0), tz).astimezone(UTC) if desde else None
    end = (
        datetime.combine(hasta + timedelta(days=1), time(0), tz).astimezone(UTC)
        if hasta
        else None
    )
    return start, end


def local_text(moment: datetime | None) -> str:
    """`2026-11-05 09:30` en la hora de la agenda; vacio si no hay fecha."""
    if moment is None:
        return ""
    return moment.astimezone(_tz()).strftime("%Y-%m-%d %H:%M")
