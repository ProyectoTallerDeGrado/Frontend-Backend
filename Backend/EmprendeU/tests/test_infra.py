"""Pruebas de la infraestructura transversal (fase 0)."""

import pytest
from httpx import ASGITransport, AsyncClient
from starlette.requests import Request

from emprendeu.core.client_ip import client_ip
from emprendeu.core.errors import Unauthorized
from emprendeu.core.pagination import Page, PageParams
from emprendeu.core.ratelimit import SlidingWindowLimiter
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


def _request(peer: str, forwarded: str | None = None) -> Request:
    headers = [(b"x-forwarded-for", forwarded.encode())] if forwarded else []
    return Request({"type": "http", "client": (peer, 1234), "headers": headers})


def test_client_ip_solo_cree_al_proxy_de_confianza() -> None:
    # Desde un proxy de confianza vale la IP reenviada (la ultima que no es un proxy).
    assert client_ip(_request("127.0.0.1", "203.0.113.7")) == "203.0.113.7"
    assert client_ip(_request("127.0.0.1", "10.9.9.9, 203.0.113.7, 127.0.0.1")) == (
        "203.0.113.7"
    )
    # Sin cabecera, o con basura, queda la IP de quien conecta.
    assert client_ip(_request("127.0.0.1")) == "127.0.0.1"
    assert client_ip(_request("127.0.0.1", "no-es-una-ip")) == "127.0.0.1"
    # Un cliente cualquiera no puede hacerse pasar por otra IP.
    assert client_ip(_request("198.51.100.4", "203.0.113.7")) == "198.51.100.4"


def test_limitador_borra_las_claves_vencidas() -> None:
    limiter = SlidingWindowLimiter(max_attempts=2, window_seconds=0)
    limiter.hit("a")
    assert not limiter.is_blocked("a")
    assert limiter._hits == {}
