"""Base declarativa comun a todos los modulos.

Las tablas viven en el schema `cieu`, igual que en
`database/EmprendeU_postgresql.sql`, que es la referencia del modelo.

No se define `naming_convention` a proposito: los nombres de constraints e
indices del esquema existente no siguen un patron unico, asi que cada modelo
los declara de forma explicita para que coincidan exactamente con el SQL.
"""

from sqlalchemy import MetaData
from sqlalchemy.orm import DeclarativeBase

DB_SCHEMA = "cieu"


class Base(DeclarativeBase):
    metadata = MetaData(schema=DB_SCHEMA)
