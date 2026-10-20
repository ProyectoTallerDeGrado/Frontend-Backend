"""Router raiz de /api/v1: agrega los routers de los modulos.

Cada modulo que exponga HTTP se incluye aqui y solo aqui.
"""

from fastapi import APIRouter

api_router = APIRouter()

# include_router de cada modulo, p. ej.:
# from emprendeu.modules.users import router as users_router
# api_router.include_router(users_router, prefix="/users", tags=["users"])
