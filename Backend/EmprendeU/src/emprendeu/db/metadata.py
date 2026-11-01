"""Punto unico que agrega los modelos de todos los modulos.

Importar este modulo garantiza que `Base.metadata` contenga las 38 tablas del
schema `cieu`. Lo usan las migraciones de Alembic (`db/migrations/env.py`) y
cualquier herramienta que necesite el esquema completo.

Es el equivalente de `api/v1.py` para los routers: el unico sitio donde se
enumeran los modulos. `db/base.py` y `core/` siguen sin conocer `modules/`.
"""

from emprendeu.db.base import Base
from emprendeu.modules import (  # noqa: F401  (import por efecto: registra las tablas)
    ai_assistant,
    alerts,
    audit,
    documents,
    entrepreneurs,
    gamification,
    indicators,
    mentoring,
    training,
    users,
    ventures,
)

__all__ = ["Base"]
