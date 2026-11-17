"""Asistente de ayuda del panel (Gemini simulado) y bandera del tutorial guiado."""

from httpx import AsyncClient

from emprendeu.core.config import get_settings
from tests.conftest import MakeUser

API = "/api/v1"


def _fake(client: AsyncClient):
    return client._transport.app.state.fake_help_llm  # type: ignore[attr-defined]


async def test_ayuda_responde_con_ia_segun_rol_y_ruta(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="asesor", email="asesor@test.com")
    h = await login("asesor@test.com")
    body = {
        "mensaje": "Como registro una sesion?",
        "ruta": "/mentoring/sessions",
        "historial": [
            {"rol": "user", "texto": "hola"},
            {"rol": "assistant", "texto": "Hola, en que te ayudo?"},
        ],
    }
    response = await client.post(f"{API}/ai/help", json=body, headers=h)
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["origen"] == "ia"
    assert data["restantes_hoy"] == get_settings().help_daily_limit - 1
    fake = _fake(client)
    assert "Asesor" in fake.last_system
    assert "/mentoring/sessions" in fake.last_system
    # La guia del asesor incluye su disponibilidad pero no la gestion de usuarios.
    assert "Mi disponibilidad" in fake.last_system
    assert "## Usuarios" not in fake.last_system
    assert fake.last_history == [
        ("user", "hola"),
        ("assistant", "Hola, en que te ayudo?"),
    ]


async def test_ayuda_sin_sesion_es_401(client: AsyncClient) -> None:
    response = await client.post(f"{API}/ai/help", json={"mensaje": "hola"})
    assert response.status_code == 401


async def test_ayuda_usa_la_guia_si_gemini_falla_y_devuelve_el_cupo(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    h = await login("admin@test.com")
    fake = _fake(client)
    fake.down = True
    response = await client.post(
        f"{API}/ai/help", json={"mensaje": "Como creo un usuario nuevo?"}, headers=h
    )
    assert response.status_code == 200
    data = response.json()
    assert data["origen"] == "guia" and data["restantes_hoy"] is None
    assert "Usuarios" in data["respuesta"]
    # El cupo de la llamada fallida se devolvio: la siguiente vuelve a tener todo menos una.
    fake.down = False
    again = (
        await client.post(f"{API}/ai/help", json={"mensaje": "hola"}, headers=h)
    ).json()
    assert again["restantes_hoy"] == get_settings().help_daily_limit - 1


async def test_ayuda_sin_clave_no_llama_a_gemini(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="coordinador", email="coord@test.com")
    h = await login("coord@test.com")
    fake = _fake(client)
    fake.configured = False
    response = await client.post(
        f"{API}/ai/help",
        json={"mensaje": "donde descargo un reporte en excel?"},
        headers=h,
    )
    assert response.json()["origen"] == "guia"
    assert "Reportes" in response.json()["respuesta"]
    assert fake.calls == 0


async def test_ayuda_respeta_la_cuota_diaria(
    client: AsyncClient, make_user: MakeUser, login, monkeypatch
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    h = await login("admin@test.com")
    monkeypatch.setattr(get_settings(), "help_daily_limit", 2)
    origins = [
        (
            await client.post(f"{API}/ai/help", json={"mensaje": "hola"}, headers=h)
        ).json()["origen"]
        for _ in range(3)
    ]
    assert origins == ["ia", "ia", "guia"]
    assert _fake(client).calls == 2


async def test_tutorial_se_marca_y_se_reinicia(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="coordinador", email="coord@test.com")
    h = await login("coord@test.com")
    me = (await client.get(f"{API}/auth/me", headers=h)).json()
    assert me["tutorial_completado_at"] is None
    done = await client.post(f"{API}/auth/me/tutorial", headers=h)
    assert done.status_code == 200 and done.json()["tutorial_completado_at"]
    me = (await client.get(f"{API}/auth/me", headers=h)).json()
    assert me["tutorial_completado_at"] is not None
    reset = await client.delete(f"{API}/auth/me/tutorial", headers=h)
    assert reset.status_code == 200 and reset.json()["tutorial_completado_at"] is None
    assert (await client.post(f"{API}/auth/me/tutorial")).status_code == 401
