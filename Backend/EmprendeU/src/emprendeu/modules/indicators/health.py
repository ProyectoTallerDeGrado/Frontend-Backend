"""Puntaje de salud de un emprendimiento (0-100) a partir de señales que ya existen.

Parte de 100 y resta por cada señal de riesgo, con topes para que una sola no lo
domine. Cada descuento deja un **motivo legible**: el número solo sirve para
ordenar; lo que guía a coordinación es saber por qué.
"""

from __future__ import annotations

from dataclasses import dataclass

# Descuentos (puntos) y topes. Si se cambian, actualizar AGENTS.md del backend.
PER_OPEN_ALERT, MAX_ALERTS = 10, 30
PER_OVERDUE_COMMITMENT, MAX_OVERDUE = 8, 24
IDLE_PENALTY, IDLE_DOUBLE_PENALTY = 10, 20  # pasado el límite / el doble del límite
STAGE_SLOW_DAYS, STAGE_SLOW_PENALTY = 120, 10
STAGE_STUCK_DAYS, STAGE_STUCK_PENALTY = 180, 15
LOW_SENTIMENT, LOW_SENTIMENT_PENALTY = -0.2, 15  # índice promedio de -1 a 1
SENTIMENT_DROP, SENTIMENT_DROP_PENALTY = 0.25, 10  # caída frente al periodo anterior

GREEN, AMBER = 70, 40  # verde >= 70, ámbar 40-69, rojo < 40


@dataclass(frozen=True, slots=True)
class HealthSignals:
    open_alerts: int = 0
    overdue_commitments: int = 0
    idle_days: int | None = None  # None = sin referencia
    idle_limit_days: int = 30  # `dias_inactividad` de los parámetros de seguimiento
    stage_days: int | None = None  # None = sin etapa activa
    sentiment_recent: float | None = None
    sentiment_previous: float | None = None


@dataclass(frozen=True, slots=True)
class HealthScore:
    score: int
    level: str  # verde | ambar | rojo
    reasons: list[str]


def _plural(n: int, one: str, many: str) -> str:
    return f"{n} {one if n == 1 else many}"


def score_venture(sig: HealthSignals) -> HealthScore:
    score = 100
    reasons: list[str] = []

    if sig.open_alerts:
        score -= min(sig.open_alerts * PER_OPEN_ALERT, MAX_ALERTS)
        reasons.append(
            _plural(sig.open_alerts, "alerta sin resolver", "alertas sin resolver")
        )
    if sig.overdue_commitments:
        score -= min(sig.overdue_commitments * PER_OVERDUE_COMMITMENT, MAX_OVERDUE)
        reasons.append(
            _plural(
                sig.overdue_commitments, "compromiso vencido", "compromisos vencidos"
            )
        )
    if sig.idle_days is not None and sig.idle_days > sig.idle_limit_days:
        double = sig.idle_days >= 2 * sig.idle_limit_days
        score -= IDLE_DOUBLE_PENALTY if double else IDLE_PENALTY
        reasons.append(f"{sig.idle_days} días sin actividad")
    if sig.stage_days is not None and sig.stage_days >= STAGE_SLOW_DAYS:
        stuck = sig.stage_days >= STAGE_STUCK_DAYS
        score -= STAGE_STUCK_PENALTY if stuck else STAGE_SLOW_PENALTY
        reasons.append(f"{sig.stage_days} días en la misma etapa")
    if sig.sentiment_recent is not None:
        if sig.sentiment_recent <= LOW_SENTIMENT:
            score -= LOW_SENTIMENT_PENALTY
            reasons.append("ánimo bajo en el coach")
        elif (
            sig.sentiment_previous is not None
            and sig.sentiment_previous - sig.sentiment_recent >= SENTIMENT_DROP
        ):
            score -= SENTIMENT_DROP_PENALTY
            reasons.append("el ánimo en el coach bajó")

    score = max(0, min(100, score))
    level = "verde" if score >= GREEN else "ambar" if score >= AMBER else "rojo"
    return HealthScore(score, level, reasons)
