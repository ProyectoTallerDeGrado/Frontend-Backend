"""Router raiz de /api/v1: agrega los routers de los modulos.

Cada modulo que exponga HTTP se incluye aqui y solo aqui.
"""

from fastapi import APIRouter

from emprendeu.modules.ai_assistant.router import router as ai_router
from emprendeu.modules.alerts.router import router as alerts_router
from emprendeu.modules.audit.router import router as audit_router
from emprendeu.modules.documents.router import router as documents_router
from emprendeu.modules.entrepreneurs.router import applications_router
from emprendeu.modules.entrepreneurs.router import router as entrepreneurs_router
from emprendeu.modules.gamification.router import router as gamification_router
from emprendeu.modules.indicators.router import router as indicators_router
from emprendeu.modules.mentoring.router import router as mentoring_router
from emprendeu.modules.training.router import router as training_router
from emprendeu.modules.users import router as users_router
from emprendeu.modules.ventures.router import router as ventures_router

api_router = APIRouter()

api_router.include_router(users_router)
api_router.include_router(audit_router)
api_router.include_router(entrepreneurs_router)
api_router.include_router(applications_router)
api_router.include_router(ventures_router)
api_router.include_router(gamification_router)
api_router.include_router(mentoring_router)
api_router.include_router(ai_router)
api_router.include_router(alerts_router)
api_router.include_router(indicators_router)
api_router.include_router(training_router)
api_router.include_router(documents_router)
