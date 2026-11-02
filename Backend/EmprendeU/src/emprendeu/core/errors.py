"""Excepciones base y handlers del formato de error global."""

from typing import Any

import structlog
from fastapi import FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class DomainError(Exception):
    """Error de negocio. Cada modulo deriva sus excepciones de esta clase."""

    code: str = "domain_error"
    status_code: int = 400

    def __init__(self, message: str, *, details: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.details = details


class NotFoundError(DomainError):
    code = "not_found"
    status_code = 404


class ConflictError(DomainError):
    code = "conflict"
    status_code = 409


class Unauthorized(DomainError):
    """Falta autenticacion o es invalida (401)."""

    code = "unauthorized"
    status_code = 401


class TooManyRequests(DomainError):
    """Demasiados intentos en una ventana de tiempo (429)."""

    code = "rate_limited"
    status_code = 429


class Forbidden(DomainError):
    """Autenticado pero sin permiso para la accion (403)."""

    code = "forbidden"
    status_code = 403


def _payload(code: str, message: str, details: Any | None = None) -> dict[str, Any]:
    return {"error": {"code": code, "message": message, "details": details}}


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(DomainError)
    async def _domain(_: Request, exc: DomainError) -> JSONResponse:
        headers: dict[str, str] | None = None
        if exc.status_code == 401:
            headers = {"WWW-Authenticate": "Bearer"}
        elif exc.status_code == 429 and exc.details and "retry_after" in exc.details:
            headers = {"Retry-After": str(exc.details["retry_after"])}
        return JSONResponse(
            status_code=exc.status_code,
            content=_payload(exc.code, exc.message, exc.details),
            headers=headers,
        )

    @app.exception_handler(Exception)
    async def _unexpected(_: Request, exc: Exception) -> JSONResponse:
        structlog.get_logger("errors").error("unhandled", error=repr(exc), exc_info=exc)
        return JSONResponse(
            status_code=500,
            content=_payload("internal_error", "Error interno del servidor."),
        )

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=_payload("http_error", str(exc.detail)),
        )

    @app.exception_handler(RequestValidationError)
    async def _validation(_: Request, exc: RequestValidationError) -> JSONResponse:
        return JSONResponse(
            status_code=422,
            content=_payload(
                "validation_error",
                "Datos de entrada invalidos",
                # `ctx` puede traer la excepcion original (un ValueError de un
                # validador): se pasa a texto para que sea serializable.
                jsonable_encoder(exc.errors(), custom_encoder={Exception: str}),
            ),
        )


class PayloadTooLarge(DomainError):
    """Cuerpo o archivo por encima del limite permitido (413)."""

    code = "payload_too_large"
    status_code = 413
