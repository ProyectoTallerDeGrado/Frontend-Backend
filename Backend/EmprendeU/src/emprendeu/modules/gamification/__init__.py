"""Modulo gamification: retos, XP, niveles e insignias.

API publica: `GamificationService` (`award_event`, `is_challenge_completed`,
`last_activity_by_venture`). El `router` lo importa `api/v1.py`.
"""

from emprendeu.modules.gamification.models import (
    EmprendedorInsignia,
    EmprendimientoReto,
    Insignia,
    MovimientoXp,
    Reto,
)
from emprendeu.modules.gamification.service import GamificationService

__all__ = [
    "EmprendedorInsignia",
    "EmprendimientoReto",
    "GamificationService",
    "Insignia",
    "MovimientoXp",
    "Reto",
]
