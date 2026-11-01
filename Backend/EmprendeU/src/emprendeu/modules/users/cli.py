"""Comandos de administracion de users.

Crear el primer administrador (no existe registro publico de administradores):

    uv run python -m emprendeu.modules.users.cli create-admin \
        --email admin@uagrm.edu.bo --nombre "Jhonny Roca" --password '...'

Sin `--password` la pide por consola.
"""

import argparse
import asyncio
import getpass
import sys

from emprendeu.core.security import hash_password
from emprendeu.db.session import get_engine, get_sessionmaker
from emprendeu.modules.users.exceptions import EmailAlreadyRegistered
from emprendeu.modules.users.models import Usuario
from emprendeu.modules.users.permissions import ADMIN_ROLE
from emprendeu.modules.users.repository import UserRepository
from emprendeu.modules.users.service import split_full_name


async def create_admin(email: str, nombre_completo: str, password: str) -> int:
    nombre, apellido = split_full_name(nombre_completo)
    async with get_sessionmaker()() as session:
        repo = UserRepository(session)
        role = await repo.get_role_by_name(ADMIN_ROLE)
        if role is None:
            raise SystemExit(
                "Falta el rol administrador: ejecuta `alembic upgrade head`."
            )
        if await repo.get_user_by_email(email.lower()) is not None:
            raise EmailAlreadyRegistered
        user = await repo.add_user(
            Usuario(
                nombre=nombre,
                apellido=apellido,
                email=email.strip().lower(),
                password_hash=hash_password(password),
                estado="habilitada",
            ),
            role.rol_id,
        )
        await repo.commit()
        return user.usuario_id


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="emprendeu-users")
    sub = parser.add_subparsers(dest="command", required=True)
    admin = sub.add_parser("create-admin", help="Crea un usuario administrador")
    admin.add_argument("--email", required=True)
    admin.add_argument("--nombre", required=True, help="Nombre y apellido")
    admin.add_argument("--password")
    args = parser.parse_args(argv)

    password = args.password or getpass.getpass("Contrasena (min. 8): ")
    if len(password) < 8:
        print("La contrasena debe tener al menos 8 caracteres.", file=sys.stderr)
        return 2

    async def run() -> int:
        try:
            return await create_admin(args.email, args.nombre, password)
        finally:
            await get_engine().dispose()

    try:
        usuario_id = asyncio.run(run())
    except EmailAlreadyRegistered:
        print("Ya existe un usuario con ese correo.", file=sys.stderr)
        return 1
    print(f"Administrador creado (usuarioid={usuario_id}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
