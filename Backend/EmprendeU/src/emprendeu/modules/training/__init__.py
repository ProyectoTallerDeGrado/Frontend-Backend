"""Modulo training: capacitaciones, inscripciones y asistencia.

El `router` lo importa `api/v1.py`.
"""

from emprendeu.modules.training.models import Capacitacion, CapacitacionParticipante
from emprendeu.modules.training.service import TrainingService

__all__ = ["Capacitacion", "CapacitacionParticipante", "TrainingService"]
