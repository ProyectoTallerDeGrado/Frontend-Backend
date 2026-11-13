"""Niveles de XP. Umbral = XP acumulado minimo para alcanzar el nivel."""

LEVEL_THRESHOLDS: tuple[tuple[int, int], ...] = (
    (1, 0),
    (2, 200),
    (3, 400),
    (4, 700),
    (5, 1100),
)


def level_for(xp: int) -> int:
    level = 1
    for number, threshold in LEVEL_THRESHOLDS:
        if xp >= threshold:
            level = number
    return level


def next_threshold(xp: int) -> int | None:
    """XP del siguiente nivel, o `None` en el nivel maximo."""
    for _, threshold in LEVEL_THRESHOLDS:
        if xp < threshold:
            return threshold
    return None


def progress_for(xp: int) -> tuple[int | None, float]:
    """(XP del siguiente nivel, % de avance dentro del nivel actual)."""
    target = next_threshold(xp)
    if target is None:
        return None, 100.0
    level = level_for(xp)
    floor = max(t for n, t in LEVEL_THRESHOLDS if n == level)
    return target, round((xp - floor) / (target - floor) * 100, 1)
