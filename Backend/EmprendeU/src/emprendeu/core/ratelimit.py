"""Limitador de intentos en memoria (ventana deslizante).

Vale para un solo proceso. Con varias replicas hay que mover el contador a un
almacen compartido (p. ej. Redis); la interfaz publica no cambia.
"""

import time
from collections import defaultdict, deque


class SlidingWindowLimiter:
    def __init__(self, max_attempts: int, window_seconds: int) -> None:
        self.max_attempts = max_attempts
        self.window_seconds = window_seconds
        self._hits: dict[str, deque[float]] = defaultdict(deque)

    def _prune(self, key: str, now: float) -> deque[float]:
        hits = self._hits[key]
        while hits and now - hits[0] > self.window_seconds:
            hits.popleft()
        return hits

    def is_blocked(self, key: str) -> bool:
        return len(self._prune(key, time.monotonic())) >= self.max_attempts

    def retry_after(self, key: str) -> int:
        hits = self._prune(key, time.monotonic())
        if not hits:
            return 0
        return max(1, int(self.window_seconds - (time.monotonic() - hits[0])))

    def hit(self, key: str) -> None:
        self._prune(key, time.monotonic()).append(time.monotonic())

    def reset(self, key: str | None = None) -> None:
        if key is None:
            self._hits.clear()
        else:
            self._hits.pop(key, None)
