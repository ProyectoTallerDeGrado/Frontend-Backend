"""Fixtures de pytest: base de pruebas real, sesion con rollback y cliente HTTP.

Las pruebas usan una base `<nombre>_test` en el mismo servidor que `DATABASE_URL`.
Su esquema se crea con `alembic upgrade head` (asi tambien se prueban las
migraciones y los datos semilla) y cada test corre dentro de una transaccion que
se revierte al terminar.
"""

import os
import subprocess
import sys
import tempfile
from collections.abc import AsyncIterator, Iterator
from contextlib import asynccontextmanager
from pathlib import Path

import psycopg
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import make_url
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, create_async_engine
from sqlalchemy.pool import NullPool

os.environ.setdefault("JWT_SECRET", "secreto-solo-para-tests-0123456789abcdef")
os.environ["UPLOAD_DIR"] = tempfile.mkdtemp(prefix="emprendeu-uploads-")

from emprendeu.core.config import Settings, get_settings  # noqa: E402

ROOT = Path(__file__).parent


def _test_url() -> str:
    base = make_url(Settings().database_url)  # type: ignore[call-arg]
    return base.set(database=f"{base.database}_test").render_as_string(
        hide_password=False
    )


TEST_DATABASE_URL = _test_url()
os.environ["DATABASE_URL"] = TEST_DATABASE_URL
get_settings.cache_clear()


def _psycopg_dsn(url: str, database: str | None = None) -> str:
    parsed = make_url(url).set(drivername="postgresql")
    if database:
        parsed = parsed.set(database=database)
    return parsed.render_as_string(hide_password=False)


@pytest.fixture(scope="session", autouse=True)
def _database() -> Iterator[None]:
    """Crea la base de pruebas si falta y deja el esquema recien migrado."""
    name = make_url(TEST_DATABASE_URL).database
    with psycopg.connect(
        _psycopg_dsn(TEST_DATABASE_URL, "postgres"), autocommit=True
    ) as admin:
        exists = admin.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s", (name,)
        ).fetchone()
        if not exists:
            admin.execute(f'CREATE DATABASE "{name}"')
    with psycopg.connect(_psycopg_dsn(TEST_DATABASE_URL), autocommit=True) as conn:
        conn.execute("DROP SCHEMA IF EXISTS cieu CASCADE")
    subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    yield


@pytest.fixture(scope="session")
async def engine() -> AsyncIterator[AsyncEngine]:
    eng = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool)
    yield eng
    await eng.dispose()


@pytest.fixture
async def session(engine: AsyncEngine) -> AsyncIterator[AsyncSession]:
    """Sesion dentro de una transaccion externa que siempre se revierte.

    `commit()` del codigo bajo prueba solo libera un savepoint.
    """
    async with engine.connect() as connection:
        transaction = await connection.begin()
        async with AsyncSession(
            bind=connection,
            expire_on_commit=False,
            join_transaction_mode="create_savepoint",
        ) as s:
            yield s
        await transaction.rollback()


@pytest.fixture
async def client(session: AsyncSession) -> AsyncIterator[AsyncClient]:
    """Cliente HTTP; `client._transport.app.state.fake_llm` es el LLM simulado."""
    from emprendeu.core.mailer import get_mailer
    from emprendeu.db.session import get_session, get_session_factory
    from emprendeu.main import create_app
    from emprendeu.modules.ai_assistant import get_help_llm, get_llm
    from emprendeu.modules.notifications import set_push_dispatcher
    from tests.fakes import FakeHelpLLM, FakeLLM, FakeMailer, FakePushDispatcher

    app = create_app()
    app.state.fake_llm = FakeLLM()
    app.dependency_overrides[get_llm] = lambda: app.state.fake_llm
    # Nunca se llama a Gemini de verdad en los tests.
    app.state.fake_help_llm = FakeHelpLLM()
    app.dependency_overrides[get_help_llm] = lambda: app.state.fake_help_llm
    app.state.fake_mailer = FakeMailer()
    app.dependency_overrides[get_mailer] = lambda: app.state.fake_mailer
    # Los push nunca salen a FCM: se guardan en `app.state.fake_push`.
    app.state.fake_push = FakePushDispatcher()
    set_push_dispatcher(app.state.fake_push)

    async def _override() -> AsyncIterator[AsyncSession]:
        yield session

    app.dependency_overrides[get_session] = _override

    # Las tareas en segundo plano usan la misma sesion (y transaccion) del test.
    @asynccontextmanager
    async def _same_session() -> AsyncIterator[AsyncSession]:
        yield session

    app.dependency_overrides[get_session_factory] = lambda: _same_session
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c
    set_push_dispatcher(None)
