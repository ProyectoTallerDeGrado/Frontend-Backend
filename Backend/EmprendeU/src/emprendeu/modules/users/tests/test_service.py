"""Pruebas unitarias del servicio y del repositorio de users."""

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.users.dependencies import build_user_service
from emprendeu.modules.users.exceptions import (
    EmailAlreadyRegistered,
    InvalidCredentials,
    InvalidFullName,
)
from emprendeu.modules.users.service import UserService, split_full_name


@pytest.fixture
def service(session: AsyncSession) -> UserService:
    return build_user_service(session)


def test_split_full_name() -> None:
    assert split_full_name("Camila Justiniano Rojas") == ("Camila", "Justiniano Rojas")
    assert split_full_name("  Ana   Lopez ") == ("Ana", "Lopez")
    with pytest.raises(InvalidFullName):
        split_full_name("Camila")


async def test_login_actualiza_ultimo_acceso(service: UserService) -> None:
    user = await service.register("Ana Lopez", "ana@test.com", "clave-larga-1")
    assert user.ultimo_acceso is None
    logged, token, expires_in = await service.login("ana@test.com", "clave-larga-1")
    assert logged.ultimo_acceso is not None
    assert token and expires_in > 0


async def test_login_con_clave_incorrecta(service: UserService) -> None:
    await service.register("Ana Lopez", "ana@test.com", "clave-larga-1")
    with pytest.raises(InvalidCredentials):
        await service.login("ana@test.com", "otra-clave")


async def test_correo_unico_sin_distinguir_mayusculas(service: UserService) -> None:
    await service.register("Ana Lopez", "ana@test.com", "clave-larga-1")
    with pytest.raises(EmailAlreadyRegistered):
        await service.register("Otra Ana", "ANA@test.com", "clave-larga-1")
