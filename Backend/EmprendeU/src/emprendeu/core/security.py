"""Hash de contrasenas (argon2 via pwdlib) y tokens JWT (PyJWT)."""

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


def create_access_token(subject: int) -> tuple[str, int]:
    """Devuelve `(token, segundos_de_vida)` para el usuario `subject`."""
    settings = get_settings()
    now = datetime.now(UTC)
    lifetime = timedelta(minutes=settings.access_token_expire_minutes)
    payload = {"sub": str(subject), "iat": now, "exp": now + lifetime}
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return token, int(lifetime.total_seconds())


def decode_access_token(token: str) -> tuple[int, datetime]:
    """Devuelve `(usuario_id, emitido_en)` del token o lanza `Unauthorized`."""
    settings = get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
            options={"require": ["sub", "exp", "iat"]},
        )
        return int(payload["sub"]), datetime.fromtimestamp(payload["iat"], UTC)
    except (jwt.PyJWTError, ValueError) as exc:
        raise Unauthorized("Token invalido o expirado") from exc
