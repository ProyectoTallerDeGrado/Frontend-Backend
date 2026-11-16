"""Envio de correo por SMTP, detras de una interfaz para poder probarlo."""

from email.message import EmailMessage
from typing import Protocol

import aiosmtplib

from emprendeu.core.config import get_settings
from emprendeu.core.errors import DomainError


class EmailUnavailable(DomainError):
    """No hay servidor SMTP configurado o no respondio (503)."""

    code = "email_unavailable"
    status_code = 503

    def __init__(self) -> None:
        super().__init__("No se pudo enviar el correo. Intenta de nuevo mas tarde.")


class Mailer(Protocol):
    async def send(self, to: str, subject: str, body: str) -> None: ...


class SmtpMailer:
    """Cliente SMTP asincrono. Lee la configuracion de `Settings`."""

    async def send(self, to: str, subject: str, body: str) -> None:
        settings = get_settings()
        if not settings.smtp_host:
            raise EmailUnavailable
        message = EmailMessage()
        message["From"] = settings.smtp_from
        message["To"] = to
        message["Subject"] = subject
        message.set_content(body)
        try:
            await aiosmtplib.send(
                message,
                hostname=settings.smtp_host,
                port=settings.smtp_port,
                username=settings.smtp_user or None,
                password=settings.smtp_password or None,
                start_tls=settings.smtp_starttls,
                timeout=15,
            )
        except (aiosmtplib.SMTPException, OSError) as error:
            raise EmailUnavailable from error


def get_mailer() -> Mailer:
    """Dependencia de FastAPI; las pruebas la reemplazan con un doble."""
    return SmtpMailer()
