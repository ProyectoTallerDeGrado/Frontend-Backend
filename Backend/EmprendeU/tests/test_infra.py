"""Pruebas de la infraestructura transversal (fase 0)."""

import pytest
from httpx import ASGITransport, AsyncClient

from emprendeu.core.errors import Unauthorized
from emprendeu.core.pagination import Page, PageParams
from emprendeu.core.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)


async def test_health_usa_la_base_de_datos(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "ok"}
    assert response.headers["X-Request-ID"]


async def test_error_de_validacion_usa_el_formato_global(client: AsyncClient) -> None:
    response = await client.get("/api/v1/openapi.json")
    assert response.status_code == 200
    missing = await client.get("/no-existe")
    assert missing.status_code == 404
    assert missing.json()["error"]["code"] == "http_error"


def test_hash_y_verificacion_de_contrasena() -> None:
    hashed = hash_password("clave-segura-123")
    assert hashed != "clave-segura-123"
    assert verify_password("clave-segura-123", hashed)
    assert not verify_password("otra", hashed)
    assert not verify_password("cualquiera", None)


def test_token_ida_y_vuelta() -> None:
    token, expires_in = create_access_token(42)
    assert expires_in > 0
    assert decode_access_token(token) == 42


def test_token_invalido_lanza_unauthorized() -> None:
    with pytest.raises(Unauthorized):
        decode_access_token("no.es.un.token")


def test_paginacion() -> None:
    params = PageParams(page=3, page_size=10)
    assert params.offset == 20
    page = Page[int].build([1, 2], params, total=22)
    assert page.model_dump() == {
        "items": [1, 2],
        "page": 3,
        "page_size": 10,
        "total": 22,
    }


async def test_openapi_describe_todos_los_modulos(client: AsyncClient) -> None:
    schema = (await client.get("/api/v1/openapi.json")).json()
    tags = {
        t
        for op in schema["paths"].values()
        for m in op.values()
        for t in m.get("tags", [])
    }
    assert tags >= {
        "auth",
        "users",
        "roles",
        "audit",
        "entrepreneurs",
        "ventures",
        "gamification",
        "mentoring",
        "ai",
        "alerts",
        "indicators",
        "training",
        "documents",
    }
    assert "/api/v1/auth/login" in schema["paths"]
    assert len(schema["paths"]) > 60


async def test_error_inesperado_no_filtra_detalles() -> None:
    from fastapi import FastAPI

    from emprendeu.core.errors import register_error_handlers

    app = FastAPI()
    register_error_handlers(app)

    @app.get("/boom")
    async def boom() -> None:
        raise RuntimeError("secreto interno")

    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        response = await c.get("/boom")
    assert response.status_code == 500
    assert response.json() == {
        "error": {
            "code": "internal_error",
            "message": "Error interno del servidor.",
            "details": None,
        }
    }


def test_produccion_exige_secreto_fuerte(monkeypatch: pytest.MonkeyPatch) -> None:
    from pydantic import ValidationError

    from emprendeu.core.config import Settings

    monkeypatch.setenv("ENVIRONMENT", "production")
    monkeypatch.setenv("JWT_SECRET", "corto")
    with pytest.raises(ValidationError):
        Settings()  # type: ignore[call-arg]
    monkeypatch.setenv("JWT_SECRET", "x" * 40)
    assert Settings().is_production  # type: ignore[call-arg]


@pytest.mark.parametrize("environment", ["development", "production"])
def test_el_secreto_debe_ser_fuerte_en_cualquier_entorno(
    monkeypatch: pytest.MonkeyPatch, environment: str
) -> None:
    """Corto o igual al de `.env.example`: no arranca, tampoco en desarrollo."""
    from pydantic import ValidationError

    from emprendeu.core.config import Settings

    monkeypatch.setenv("ENVIRONMENT", environment)
    for weak in ("corto", "cambia-este-secreto-en-tu-entorno", "a" * 31):
        monkeypatch.setenv("JWT_SECRET", weak)
        with pytest.raises(ValidationError):
            Settings()  # type: ignore[call-arg]
    monkeypatch.setenv("JWT_SECRET", "a-1" * 11)  # 33 caracteres, no es el de ejemplo
    assert Settings().environment == environment  # type: ignore[call-arg]


def test_el_limitador_no_acumula_claves_vencidas(monkeypatch) -> None:
    """Una clave que no vuelve no debe quedarse en memoria para siempre."""
    import time

    from emprendeu.core import ratelimit
    from emprendeu.core.ratelimit import SlidingWindowLimiter

    clock = [1000.0]
    monkeypatch.setattr(time, "monotonic", lambda: clock[0])
    monkeypatch.setattr(ratelimit, "SWEEP_EVERY", 10)
    limiter = SlidingWindowLimiter(max_attempts=3, window_seconds=60)

    # consultar claves que nunca intentaron nada no deja entradas
    for i in range(50):
        assert limiter.is_blocked(f"consulta-{i}") is False
    assert limiter.tracked_keys == 0

    # 200 claves distintas (como quien rota IPs): se acumulan solo mientras su ventana vive
    for i in range(200):
        limiter.hit(f"ip-{i}")
    assert limiter.tracked_keys == 200
    clock[0] += 61  # vencen todas
    for i in range(10):  # a la proxima barrida se limpian
        limiter.hit(f"nueva-{i}")
    assert limiter.tracked_keys <= 10

    # y el bloqueo sigue funcionando
    for _ in range(3):
        limiter.hit("persona")
    assert limiter.is_blocked("persona") is True
    clock[0] += 61
    assert limiter.is_blocked("persona") is False
