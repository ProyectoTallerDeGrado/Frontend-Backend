"""Entorno de Alembic.

La URL sale de `core.config.Settings`, nunca de `alembic.ini`, para no duplicar
configuracion ni versionar credenciales.

Todas las tablas viven en el schema `cieu`, asi que se activa `include_schemas`
y se filtra con `include_name` para que el autogenerate ignore `public` y
cualquier otro schema.
"""

import asyncio
import sys
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool, text
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import create_async_engine

from emprendeu.core.config import get_settings
from emprendeu.db.base import DB_SCHEMA

# Importa los modelos de los 11 modulos y expone Base con el esquema completo.
from emprendeu.db.metadata import Base

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

settings = get_settings()


def include_name(name: str | None, type_: str, parent_names: dict) -> bool:
    """Restringe el autogenerate al schema de la aplicacion."""
    if type_ == "schema":
        return name == DB_SCHEMA
    return True


_context_opts = {
    "target_metadata": target_metadata,
    "include_schemas": True,
    "include_name": include_name,
    "compare_type": True,
    "version_table_schema": DB_SCHEMA,
}


def run_migrations_offline() -> None:
    """Genera el SQL sin conectarse a la base."""
    context.configure(
        url=settings.database_url,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        **_context_opts,
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    # La tabla de versiones vive en `cieu`, asi que el schema debe existir antes
    # de que Alembic la cree. Es idempotente.
    #
    # El commit es imprescindible: deja la conexion sin transaccion abierta. Si
    # queda una activa, el `begin_transaction()` de Alembic no la crea ni la
    # confirma, y la migracion se pierde al cerrar la conexion.
    connection.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{DB_SCHEMA}"'))
    connection.commit()

    context.configure(connection=connection, **_context_opts)

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    connectable = create_async_engine(settings.database_url, poolclass=pool.NullPool)

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    # En Windows el loop por defecto es ProactorEventLoop, que psycopg async no
    # soporta; se fuerza SelectorEventLoop. En el resto se usa el loop normal.
    loop_factory = asyncio.SelectorEventLoop if sys.platform == "win32" else None
    with asyncio.Runner(loop_factory=loop_factory) as runner:
        runner.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
