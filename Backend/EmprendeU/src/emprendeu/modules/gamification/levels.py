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
