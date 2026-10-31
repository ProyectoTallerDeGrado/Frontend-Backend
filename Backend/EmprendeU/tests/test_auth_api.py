"""Flujos de autenticacion: registro, login, /me y cuentas deshabilitadas."""

from httpx import AsyncClient

from tests.conftest import PASSWORD, MakeUser

API = "/api/v1"


async def test_registro_crea_emprendedor_y_permite_login(client: AsyncClient) -> None:
    response = await client.post(
        f"{API}/auth/register",
        json={
            "nombre_completo": "Camila Justiniano Rojas",
            "email": "  Camila@Correo.com ",
            "password": "una-clave-larga",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["nombre"] == "Camila"
    assert body["apellido"] == "Justiniano Rojas"
    assert body["email"] == "camila@correo.com"
    assert body["rol"] == "emprendedor"
    assert "password" not in body and "password_hash" not in body

    login = await client.post(
        f"{API}/auth/login",
        json={"email": "CAMILA@correo.com", "password": "una-clave-larga"},
    )
    assert login.status_code == 200
    data = login.json()
    assert data["token_type"] == "bearer"
    assert data["expires_in"] > 0
    assert data["user"]["rol"] == "emprendedor"
    assert "ia:consulta" in data["user"]["permisos"]
    assert "usuarios:administrativo" not in data["user"]["permisos"]


async def test_registro_rechaza_correo_repetido(client: AsyncClient) -> None:
    payload = {
        "nombre_completo": "Ana Lopez",
        "email": "ana@correo.com",
        "password": "una-clave-larga",
    }
    assert (await client.post(f"{API}/auth/register", json=payload)).status_code == 201
    again = await client.post(f"{API}/auth/register", json=payload)
    assert again.status_code == 409
    assert again.json()["error"]["code"] == "email_taken"


async def test_registro_valida_entrada(client: AsyncClient) -> None:
    solo_nombre = await client.post(
        f"{API}/auth/register",
        json={
            "nombre_completo": "Camila",
            "email": "c@c.com",
            "password": "una-clave-larga",
        },
    )
    assert solo_nombre.status_code == 422
    assert solo_nombre.json()["error"]["code"] == "invalid_name"

    corta = await client.post(
        f"{API}/auth/register",
        json={"nombre_completo": "Ana Lopez", "email": "a@a.com", "password": "corta"},
    )
    assert corta.status_code == 422
    assert corta.json()["error"]["code"] == "validation_error"


async def test_login_con_credenciales_incorrectas(
    client: AsyncClient, make_user: MakeUser
) -> None:
    await make_user(email="a@test.com")
    wrong = await client.post(
        f"{API}/auth/login", json={"email": "a@test.com", "password": "mala"}
    )
    unknown = await client.post(
        f"{API}/auth/login", json={"email": "nadie@test.com", "password": PASSWORD}
    )
    for response in (wrong, unknown):
        assert response.status_code == 401
        assert response.json()["error"]["code"] == "invalid_credentials"
        assert response.headers["WWW-Authenticate"] == "Bearer"


async def test_cuenta_deshabilitada_no_entra(
    client: AsyncClient, make_user: MakeUser
) -> None:
    await make_user(email="off@test.com", estado="deshabilitada")
    response = await client.post(
        f"{API}/auth/login", json={"email": "off@test.com", "password": PASSWORD}
    )
    assert response.status_code == 403
    assert response.json()["error"]["code"] == "account_disabled"


async def test_me_requiere_token_y_devuelve_permisos(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    assert (await client.get(f"{API}/auth/me")).status_code == 401
    bad = await client.get(f"{API}/auth/me", headers={"Authorization": "Bearer x.y.z"})
    assert bad.status_code == 401

    await make_user(rol="administrador", email="admin@test.com")
    headers = await login("admin@test.com")
    me = await client.get(f"{API}/auth/me", headers=headers)
    assert me.status_code == 200
    assert me.json()["email"] == "admin@test.com"
    assert me.json()["ultimo_acceso"] is not None
    assert "usuarios:administrativo" in me.json()["permisos"]


async def test_token_de_cuenta_deshabilitada_despues_del_login(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    victim = await make_user(email="v@test.com")
    admin_h = await login("admin@test.com")
    victim_h = await login("v@test.com")

    off = await client.patch(
        f"{API}/users/{victim.usuario_id}/estado",
        json={"estado": "deshabilitada"},
        headers=admin_h,
    )
    assert off.status_code == 200
    assert (await client.get(f"{API}/auth/me", headers=victim_h)).status_code == 403
