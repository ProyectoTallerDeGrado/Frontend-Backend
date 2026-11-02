"""Dependencias propias de entrepreneurs."""

from emprendeu.core.config import get_settings
from emprendeu.core.ratelimit import SlidingWindowLimiter

_limiter: SlidingWindowLimiter | None = None


def get_application_limiter() -> SlidingWindowLimiter:
    """Limitador del formulario publico de postulacion (uno por proceso)."""
    global _limiter  # noqa: PLW0603
    if _limiter is None:
        settings = get_settings()
        _limiter = SlidingWindowLimiter(
            settings.application_max_attempts, settings.application_window_seconds
        )
    return _limiter
