"""Engine asincrono y dependencia de sesion."""

from collections.abc import AsyncIterator, Callable
from contextlib import AbstractAsyncContextManager
from functools import lru_cache

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from emprendeu.core.config import get_settings


@lru_cache
def get_engine() -> AsyncEngine:
    settings = get_settings()
    return create_async_engine(
        settings.database_url,
        echo=settings.db_echo,
        pool_size=settings.db_pool_size,
        max_overflow=settings.db_max_overflow,
        pool_pre_ping=True,
    )


@lru_cache
def get_sessionmaker() -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(get_engine(), expire_on_commit=False)


async def get_session() -> AsyncIterator[AsyncSession]:
    """Dependencia de FastAPI: una sesion por request."""
    async with get_sessionmaker()() as session:
        yield session


SessionFactory = Callable[[], AbstractAsyncContextManager[AsyncSession]]


def get_session_factory() -> SessionFactory:
    """Dependencia de FastAPI para tareas en segundo plano: la sesion de la peticion ya
    no sirve cuando corren, asi que abren una propia (las pruebas la reemplazan)."""
    return get_sessionmaker()
