"""Limitador de intentos en memoria (ventana deslizante).

Vale para un solo proceso. Con varias replicas hay que mover el contador a un
almacen compartido (p. ej. Redis); la interfaz publica no cambia.
"""

import time
from collections import defaultdict, deque

# Cada cuantos intentos se limpian las claves vencidas.
SWEEP_EVERY = 256


class SlidingWindowLimiter:
    def __init__(self, max_attempts: int, window_seconds: int) -> None:
        self.max_attempts = max_attempts
        self.window_seconds = window_seconds
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._calls = 0

    def _prune(self, key: str, now: float) -> deque[float]:
        hits = self._hits[key]
        while hits and now - hits[0] > self.window_seconds:
            hits.popleft()
        return hits

    def _sweep(self, now: float) -> None:
        """Descarta las claves cuya ventana ya vencio.

        Sin esto, cada clave distinta (IP o correo) dejaria una entrada para siempre aunque
        no volviera: quien rotara claves podria hacer crecer la memoria sin limite.
        """
        for key in list(self._hits):
            if not self._prune(key, now):
                del self._hits[key]

    @property
    def tracked_keys(self) -> int:
        """Cuantas claves guarda ahora (para pruebas y diagnostico)."""
        return len(self._hits)

    def is_blocked(self, key: str) -> bool:
        blocked = len(self._prune(key, time.monotonic())) >= self.max_attempts
        if not blocked and not self._hits[key]:
            del self._hits[key]  # consultar no debe crear una entrada vacia
        return blocked

    def retry_after(self, key: str) -> int:
        hits = self._prune(key, time.monotonic())
        if not hits:
            return 0
        return max(1, int(self.window_seconds - (time.monotonic() - hits[0])))

    def hit(self, key: str) -> None:
        now = time.monotonic()
        self._calls += 1
        if self._calls % SWEEP_EVERY == 0:
            self._sweep(now)
        self._prune(key, now).append(now)

    def reset(self, key: str | None = None) -> None:
        if key is None:
            self._hits.clear()
        else:
            self._hits.pop(key, None)
