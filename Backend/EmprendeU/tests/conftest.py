"""Fixtures para las pruebas de API."""

from collections.abc import Awaitable, Callable

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.security import hash_password
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.entrepreneurs.admission_service import get_admission_limiter
from emprendeu.modules.users.dependencies import get_login_limiter
from emprendeu.modules.users.models import Usuario
from emprendeu.modules.users.repository import UserRepository

PASSWORD = "clave-de-prueba-123"

MakeUser = Callable[..., Awaitable[Usuario]]


@pytest.fixture
def make_user(session: AsyncSession) -> MakeUser:
    async def _make(
        rol: str = "emprendedor",
        email: str = "user@test.com",
        estado: str = "habilitada",
        nombre: str = "Ana",
        apellido: str = "Prueba",
    ) -> Usuario:
        repo = UserRepository(session)
        role = await repo.get_role_by_name(rol)
        assert role is not None
        created = await repo.add_user(
            Usuario(
                nombre=nombre,
                apellido=apellido,
                email=email,
                password_hash=hash_password(PASSWORD),
                estado=estado,
            ),
            role.rol_id,
        )
        if rol == "emprendedor":
            await EntrepreneurService(session).create_profile(created.usuario_id)
        return created

    return _make


@pytest.fixture
def login(client: AsyncClient) -> Callable[[str], Awaitable[dict[str, str]]]:
    async def _login(email: str) -> dict[str, str]:
        response = await client.post(
            "/api/v1/auth/login", json={"email": email, "password": PASSWORD}
        )
        assert response.status_code == 200, response.text
        return {"Authorization": f"Bearer {response.json()['access_token']}"}

    return _login


@pytest.fixture(autouse=True)
def _reset_login_limiter() -> None:
    get_login_limiter().reset()
    get_admission_limiter().reset()
