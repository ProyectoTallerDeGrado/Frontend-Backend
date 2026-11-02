"""Hash de contrasenas (argon2 via pwdlib) y tokens JWT (PyJWT)."""

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

import jwt
from pwdlib import PasswordHash

from emprendeu.core.config import get_settings
from emprendeu.core.errors import Unauthorized

_hasher = PasswordHash.recommended()

# Hash valido de una clave aleatoria: se usa para gastar el mismo tiempo cuando
# el usuario no existe y no filtrar su existencia por temporizacion.
_DUMMY_HASH = _hasher.hash("no-es-una-contrasena-real")


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password: str, password_hash: str | None) -> bool:
    """Compara en tiempo constante; con `None` consume el mismo tiempo y falla."""
    if password_hash is None:
        _hasher.verify(password, _DUMMY_HASH)
        return False
    return _hasher.verify(password, password_hash)


_EPOCH = datetime(1970, 1, 1, tzinfo=UTC)


def to_microseconds(moment: datetime) -> int:
    """Instante como microsegundos desde la epoca (aritmetica entera, sin floats)."""
    return (moment - _EPOCH) // timedelta(microseconds=1)


@dataclass(frozen=True, slots=True)
class TokenClaims:
    usuario_id: int
    # Instante de emision en microsegundos. `iat` solo tiene segundos y no sirve
    # para decidir si un token es anterior a un cambio de contrasena del mismo segundo.
    issued_us: int


def create_access_token(subject: int) -> tuple[str, int]:
    """Devuelve `(token, segundos_de_vida)` para el usuario `subject`."""
    settings = get_settings()
    now = datetime.now(UTC)
    lifetime = timedelta(minutes=settings.access_token_expire_minutes)
    payload = {
        "sub": str(subject),
        "iat": now,
        "iat_us": to_microseconds(now),
        "exp": now + lifetime,
    }
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return token, int(lifetime.total_seconds())


def decode_access_token(token: str) -> int:
    """Devuelve el id de usuario del token o lanza `Unauthorized`."""
    return decode_token_claims(token).usuario_id


def decode_token_claims(token: str) -> TokenClaims:
    """Valida firma y expiracion y devuelve el usuario y el instante de emision."""
    settings = get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
            options={"require": ["sub", "exp"]},
        )
        issued = payload.get("iat_us")
        if issued is None:  # token anterior a este campo: solo tiene segundos
            issued = int(payload.get("iat", 0)) * 1_000_000
        return TokenClaims(int(payload["sub"]), int(issued))
    except (jwt.PyJWTError, ValueError) as exc:
        raise Unauthorized("Token invalido o expirado") from exc
