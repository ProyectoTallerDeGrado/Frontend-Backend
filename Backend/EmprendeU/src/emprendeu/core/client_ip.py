"""IP del cliente real cuando la peticion llega a traves de un proxy de confianza.

La web (Next) llama a la API desde su servidor: sin esto, todas las personas que usan la
web comparten una sola IP y los limites por IP (login, recuperacion, postulaciones) las
bloquean a todas juntas.

`X-Forwarded-For` solo se cree si quien conecta esta en `TRUSTED_PROXIES`; de cualquier
otro origen se ignora, porque el cliente puede escribir en esa cabecera lo que quiera.
"""

from functools import lru_cache
from ipaddress import IPv4Network, IPv6Network, ip_address, ip_network

from starlette.requests import Request

from emprendeu.core.config import get_settings

type Network = IPv4Network | IPv6Network


@lru_cache
def _networks(entries: tuple[str, ...]) -> tuple[Network, ...]:
    return tuple(ip_network(entry, strict=False) for entry in entries)


def _is_trusted(host: str, networks: tuple[Network, ...]) -> bool:
    try:
        address = ip_address(host)
    except ValueError:
        return False
    return any(address in network for network in networks)


def client_ip(request: Request) -> str | None:
    """IP de quien hizo la peticion, o `None` si no se conoce."""
    peer = request.client.host if request.client else None
    if peer is None:
        return None
    networks = _networks(tuple(get_settings().trusted_proxies))
    if not _is_trusted(peer, networks):
        return peer
    # Cada proxy agrega al final la IP de quien le hablo: se recorre de derecha a
    # izquierda y vale la primera que no es un proxy propio.
    forwarded = request.headers.get("x-forwarded-for", "")
    for candidate in reversed([part.strip() for part in forwarded.split(",")]):
        try:
            ip_address(candidate)
        except ValueError:
            break
        if not _is_trusted(candidate, networks):
            return candidate
    return peer
