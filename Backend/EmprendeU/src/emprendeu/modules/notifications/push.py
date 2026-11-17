"""Envio de notificaciones push con Firebase Cloud Messaging (API HTTP v1).

Flujo: `NotificationService.notify` guarda el aviso en la bandeja y deja un
`PushMessage` en `session.info`. Solo cuando esa sesion hace `commit` (evento
`after_commit`) se lanza el envio en segundo plano; si la transaccion se revierte,
no sale nada. El envio abre su propia sesion para leer los tokens y borra los que
FCM declara invalidos (app desinstalada, sesion cerrada).

Sin `FCM_CREDENTIALS_FILE` el emisor no esta configurado y no se envia nada: los
avisos quedan igual en la bandeja de la app.
"""

from __future__ import annotations

import asyncio
import json
import time
from dataclasses import dataclass, field
from enum import StrEnum
from functools import lru_cache
from pathlib import Path
from typing import Any, Protocol

import httpx
import jwt
import structlog
from sqlalchemy import event
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session, SessionTransaction

from emprendeu.core.config import get_settings
from emprendeu.db.session import SessionFactory, get_sessionmaker
from emprendeu.modules.notifications.repository import NotificationRepository

log = structlog.get_logger("notifications.push")

FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
# Canal de Android que crea la app (MainActivity); si no existe, FCM usa el suyo.
ANDROID_CHANNEL = "emprendeu_avisos"
PENDING_KEY = "notifications.pending_push"


@dataclass(frozen=True, slots=True)
class PushMessage:
    user_ids: tuple[int, ...]
    title: str
    body: str
    data: dict[str, str] = field(default_factory=dict)


class PushResult(StrEnum):
    SENT = "sent"
    INVALID_TOKEN = "invalid_token"  # se borra el dispositivo
    FAILED = "failed"  # error transitorio: se conserva el dispositivo


class PushSender(Protocol):
    @property
    def configured(self) -> bool: ...

    async def send(
        self, token: str, title: str, body: str, data: dict[str, str]
    ) -> PushResult: ...


class FcmSender:
    """Cliente minimo de FCM HTTP v1 con una cuenta de servicio de Google."""

    def __init__(
        self,
        credentials: dict[str, Any] | None,
        timeout: float = 10.0,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self._creds = credentials
        self._timeout = timeout
        self._transport = transport
        self._access_token: str | None = None
        self._expires_at = 0.0
        self._lock = asyncio.Lock()

    @classmethod
    def from_settings(cls) -> FcmSender:
        settings = get_settings()
        path = settings.fcm_credentials_file.strip()
        creds: dict[str, Any] | None = None
        if path:
            try:
                creds = json.loads(Path(path).read_text(encoding="utf-8"))
                for key in ("project_id", "client_email", "private_key"):
                    if not creds.get(key):
                        raise ValueError(f"falta {key}")
            except (OSError, ValueError) as exc:
                log.warning("fcm_credenciales_invalidas", ruta=path, error=str(exc))
                creds = None
        return cls(creds, settings.fcm_timeout_seconds)

    @property
    def configured(self) -> bool:
        return self._creds is not None

    def _client(self) -> httpx.AsyncClient:
        return httpx.AsyncClient(timeout=self._timeout, transport=self._transport)

    async def _token(self, client: httpx.AsyncClient) -> str:
        """Token OAuth2 de la cuenta de servicio (JWT firmado RS256), cacheado ~1 h."""
        assert self._creds is not None
        async with self._lock:
            if self._access_token and time.time() < self._expires_at - 60:
                return self._access_token
            token_uri = self._creds.get(
                "token_uri", "https://oauth2.googleapis.com/token"
            )
            issued = int(time.time())
            assertion = jwt.encode(
                {
                    "iss": self._creds["client_email"],
                    "scope": FCM_SCOPE,
                    "aud": token_uri,
                    "iat": issued,
                    "exp": issued + 3600,
                },
                self._creds["private_key"],
                algorithm="RS256",
            )
            response = await client.post(
                token_uri,
                data={
                    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                    "assertion": assertion,
                },
            )
            response.raise_for_status()
            payload = response.json()
            self._access_token = payload["access_token"]
            self._expires_at = issued + int(payload.get("expires_in", 3600))
            return self._access_token

    async def send(
        self, token: str, title: str, body: str, data: dict[str, str]
    ) -> PushResult:
        if self._creds is None:
            return PushResult.FAILED
        url = (
            "https://fcm.googleapis.com/v1/projects/"
            f"{self._creds['project_id']}/messages:send"
        )
        message = {
            "message": {
                "token": token,
                "notification": {"title": title, "body": body},
                "data": data,
                "android": {
                    "priority": "high",
                    "notification": {"channel_id": ANDROID_CHANNEL},
                },
                "apns": {"payload": {"aps": {"sound": "default"}}},
            }
        }
        try:
            async with self._client() as client:
                access = await self._token(client)
                response = await client.post(
                    url, json=message, headers={"Authorization": f"Bearer {access}"}
                )
        except (httpx.HTTPError, KeyError, ValueError) as exc:
            log.warning("fcm_no_disponible", error=str(exc))
            return PushResult.FAILED
        if response.is_success:
            return PushResult.SENT
        if response.status_code == 401:
            self._access_token = None  # se renueva en el siguiente envio
        if _is_invalid_token(response):
            return PushResult.INVALID_TOKEN
        log.warning(
            "fcm_rechazo", status=response.status_code, cuerpo=response.text[:300]
        )
        return PushResult.FAILED


def _is_invalid_token(response: httpx.Response) -> bool:
    """404 / UNREGISTERED: la app ya no existe en ese celular o borro su token.
    400 / INVALID_ARGUMENT sobre el token: nunca fue valido."""
    if response.status_code == 404:
        return True
    if response.status_code != 400:
        return False
    try:
        error = response.json().get("error", {})
    except ValueError:
        return False
    codes = {
        d.get("errorCode") for d in error.get("details", []) if isinstance(d, dict)
    }
    if "UNREGISTERED" in codes:
        return True
    return "INVALID_ARGUMENT" in codes and "token" in str(error.get("message", ""))


class PushDispatcher:
    """Entrega una tanda de mensajes a todos los dispositivos de sus destinatarios."""

    def __init__(self, factory: SessionFactory, sender: PushSender) -> None:
        self._factory = factory
        self._sender = sender

    async def deliver(self, messages: list[PushMessage]) -> None:
        if not self._sender.configured or not messages:
            return
        async with self._factory() as session:
            repo = NotificationRepository(session)
            invalid: list[str] = []
            for message in messages:
                for _, token in await repo.tokens_for(list(message.user_ids)):
                    result = await self._sender.send(
                        token, message.title, message.body, message.data
                    )
                    if result is PushResult.INVALID_TOKEN:
                        invalid.append(token)
            if invalid:
                await repo.delete_tokens(invalid)
                await repo.commit()
                log.info("fcm_tokens_borrados", total=len(invalid))


class Dispatcher(Protocol):
    async def deliver(self, messages: list[PushMessage]) -> None: ...


_override: Dispatcher | None = None
_tasks: set[asyncio.Task[None]] = set()


@lru_cache
def _default_dispatcher() -> PushDispatcher:
    return PushDispatcher(get_sessionmaker(), FcmSender.from_settings())


def get_push_dispatcher() -> Dispatcher:
    return _override or _default_dispatcher()


def set_push_dispatcher(dispatcher: Dispatcher | None) -> None:
    """Reemplaza el despachador (las pruebas lo cambian por un doble)."""
    global _override
    _override = dispatcher


def queue_push(session: AsyncSession, message: PushMessage) -> None:
    session.info.setdefault(PENDING_KEY, []).append(message)


async def wait_for_pushes() -> None:
    """Espera los envios en curso (las tareas programadas lo llaman antes de salir)."""
    while _tasks:
        await asyncio.gather(*list(_tasks), return_exceptions=True)


async def _deliver_safely(messages: list[PushMessage]) -> None:
    try:
        await get_push_dispatcher().deliver(messages)
    except Exception:  # noqa: BLE001 - el aviso ya esta en la bandeja
        log.exception("push_fallido")


@event.listens_for(Session, "after_commit")
def _send_after_commit(session: Session) -> None:
    messages = session.info.pop(PENDING_KEY, None)
    if not messages:
        return
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:  # sesion sincronica fuera de un loop: no hay como enviar
        return
    task = loop.create_task(_deliver_safely(messages))
    _tasks.add(task)
    task.add_done_callback(_tasks.discard)


@event.listens_for(Session, "after_soft_rollback")
def _drop_on_rollback(session: Session, previous: SessionTransaction) -> None:
    if not previous.nested:
        session.info.pop(PENDING_KEY, None)
