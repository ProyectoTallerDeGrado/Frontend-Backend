"""Cliente de FCM HTTP v1 (sin red: `httpx.MockTransport`) y despachador."""

import json

import httpx
import jwt
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

from emprendeu.modules.notifications import (
    FcmSender,
    PushResult,
)

_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
CREDS = {
    "project_id": "emprendeu-test",
    "client_email": "push@emprendeu-test.iam.gserviceaccount.com",
    "private_key": _KEY.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode(),
    "token_uri": "https://oauth2.googleapis.com/token",
}


class FakeGoogle:
    """Responde como el servidor OAuth2 de Google y FCM."""

    def __init__(self, fcm_status: int = 200, fcm_body: dict | None = None) -> None:
        self.fcm_status = fcm_status
        self.fcm_body = fcm_body or {"name": "projects/x/messages/1"}
        self.token_calls = 0
        self.sent: list[dict] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        if request.url.host == "oauth2.googleapis.com":
            self.token_calls += 1
            form = dict(httpx.QueryParams(request.content.decode()))
            claims = jwt.decode(
                form["assertion"],
                _KEY.public_key(),
                algorithms=["RS256"],
                audience=CREDS["token_uri"],
            )
            assert claims["iss"] == CREDS["client_email"]
            assert "firebase.messaging" in claims["scope"]
            return httpx.Response(
                200, json={"access_token": "ya29.x", "expires_in": 3600}
            )
        assert request.url.path == "/v1/projects/emprendeu-test/messages:send"
        assert request.headers["Authorization"] == "Bearer ya29.x"
        self.sent.append(json.loads(request.content))
        return httpx.Response(self.fcm_status, json=self.fcm_body)


def _sender(google: FakeGoogle) -> FcmSender:
    return FcmSender(CREDS, transport=httpx.MockTransport(google))


async def test_envia_y_reutiliza_el_token_oauth() -> None:
    google = FakeGoogle()
    sender = _sender(google)
    for _ in range(2):
        result = await sender.send("tok", "Hola", "Cuerpo", {"ruta": "/training"})
        assert result is PushResult.SENT
    assert google.token_calls == 1
    message = google.sent[0]["message"]
    assert message["token"] == "tok"
    assert message["notification"] == {"title": "Hola", "body": "Cuerpo"}
    assert message["data"] == {"ruta": "/training"}
    assert message["android"]["priority"] == "high"


async def test_clasifica_tokens_invalidos_y_errores() -> None:
    unregistered = {
        "error": {
            "status": "NOT_FOUND",
            "message": "Requested entity was not found.",
            "details": [{"errorCode": "UNREGISTERED"}],
        }
    }
    assert (
        await _sender(FakeGoogle(404, unregistered)).send("t", "a", "b", {})
        is PushResult.INVALID_TOKEN
    )
    bad_token = {
        "error": {
            "message": "The registration token is not a valid FCM registration token",
            "details": [{"errorCode": "INVALID_ARGUMENT"}],
        }
    }
    assert (
        await _sender(FakeGoogle(400, bad_token)).send("t", "a", "b", {})
        is PushResult.INVALID_TOKEN
    )
    assert (
        await _sender(FakeGoogle(503, {"error": {}})).send("t", "a", "b", {})
        is PushResult.FAILED
    )
    # Sin credenciales no esta configurado y no intenta nada.
    assert FcmSender(None).configured is False
