"""Reglas de negocio del modulo users: autenticacion, cuentas, roles y permisos."""

from __future__ import annotations

import secrets
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from sqlalchemy.exc import IntegrityError

from emprendeu.core.config import get_settings
from emprendeu.core.errors import TooManyRequests, Unauthorized
from emprendeu.core.mailer import Mailer
from emprendeu.core.pagination import PageParams
from emprendeu.core.ratelimit import SlidingWindowLimiter
from emprendeu.core.security import (
    create_access_token,
    decode_token_claims,
    hash_password,
    to_microseconds,
    verify_password,
)
from emprendeu.modules.audit import AuditService
from emprendeu.modules.entrepreneurs import EntrepreneurService
from emprendeu.modules.users.exceptions import (
    AccountDisabled,
    AdminLockout,
    CannotDisableSelf,
    EmailAlreadyRegistered,
    InvalidCredentials,
    InvalidFullName,
    InvalidPermissions,
    InvalidResetCode,
    RoleInUse,
    RoleNameTaken,
    RoleNotFound,
    SystemRoleProtected,
    UserNotFound,
    WrongCurrentPassword,
)
from emprendeu.modules.users.models import RestablecimientoPassword, Rol, Usuario
from emprendeu.modules.users.permissions import (
    ACTIONS,
    ADMIN_REQUIRED,
    ADMIN_ROLE,
    ALL_PERMISSIONS,
    DEFAULT_ROLE,
    DISABLED,
    ENABLED,
    MODULES,
    SYSTEM_ROLES,
    permission_name,
)
from emprendeu.modules.users.repository import UserRepository


@dataclass(frozen=True, slots=True)
class CurrentUser:
    """Identidad autenticada de la peticion (sin objetos ORM)."""

    usuario_id: int
    nombre: str
    email: str
    rol: str | None
    permisos: frozenset[str]

    def can(self, permission: str) -> bool:
        return permission in self.permisos

    @property
    def is_staff(self) -> bool:
        """Todo rol distinto de emprendedor ve datos de otros emprendimientos."""
        return self.rol != DEFAULT_ROLE

    def can_staff(self, permission: str) -> bool:
        """Permiso del rol Y alcance de personal (un emprendedor solo ve lo suyo)."""
        return self.is_staff and self.can(permission)


def split_full_name(full_name: str) -> tuple[str, str]:
    """`Camila Justiniano Rojas` -> (`Camila`, `Justiniano Rojas`)."""
    parts = full_name.split()
    if len(parts) < 2:
        raise InvalidFullName
    return parts[0], " ".join(parts[1:])


class UserService:
    def __init__(
        self,
        repository: UserRepository,
        audit: AuditService,
        entrepreneurs: EntrepreneurService,
        login_limiter: SlidingWindowLimiter | None = None,
        reset_limiter: SlidingWindowLimiter | None = None,
    ) -> None:
        self._repo = repository
        self._audit = audit
        self._entrepreneurs = entrepreneurs
        self._limiter = login_limiter
        self._reset_limiter = reset_limiter

    # --- autenticacion ----------------------------------------------------

    async def login(
        self, email: str, password: str, ip: str | None = None
    ) -> tuple[Usuario, str, int]:
        email = email.strip().lower()
        key = f"{ip or '-'}|{email}"
        if self._limiter and self._limiter.is_blocked(key):
            raise TooManyRequests(
                "Demasiados intentos. Intenta de nuevo mas tarde.",
                details={"retry_after": self._limiter.retry_after(key)},
            )
        user = await self._repo.get_user_by_email(email)
        # Se verifica siempre (con hash falso si no existe) para igualar tiempos.
        valid = verify_password(password, user.password_hash if user else None)
        if user is None or not valid:
            if self._limiter:
                self._limiter.hit(key)
            await self._audit.record(
                user.usuario_id if user else None,
                "accesos.login_fallido",
                email,
                resultado="rechazado",
                ip=ip,
            )
            await self._repo.commit()
            raise InvalidCredentials
        if user.estado == DISABLED:
            await self._audit.record(
                user.usuario_id,
                "accesos.login_fallido",
                email,
                resultado="rechazado",
                despues={"motivo": "cuenta deshabilitada"},
                ip=ip,
            )
            await self._repo.commit()
            raise AccountDisabled
        if self._limiter:
            self._limiter.reset(key)
        await self._repo.touch_last_access(user)
        await self._audit.record(
            user.usuario_id, "accesos.login", "Panel web / app móvil", ip=ip
        )
        await self._repo.commit()
        token, expires_in = create_access_token(user.usuario_id)
        return user, token, expires_in

    async def register(
        self, nombre_completo: str, email: str, password: str
    ) -> Usuario:
        user = await self._create_account(
            nombre_completo, email, password, DEFAULT_ROLE
        )
        await self._audit.record(
            user.usuario_id,
            "usuarios.registro",
            user.email,
            tabla="usuario",
            id_registro=user.usuario_id,
        )
        await self._repo.commit()
        return user

    async def authenticate(self, token: str) -> CurrentUser:
        claims = decode_token_claims(token)
        user = await self._repo.get_user(claims.usuario_id)
        if user is None:
            raise Unauthorized("Token invalido o expirado")
        if user.estado == DISABLED:
            raise AccountDisabled
        changed = user.password_changed_at
        if changed is not None and claims.issued_us < to_microseconds(changed):
            raise Unauthorized("La contrasena cambio: inicia sesion de nuevo.")
        return await self.current_user(user)

    async def get_user(self, usuario_id: int) -> Usuario:
        user = await self._repo.get_user(usuario_id)
        if user is None:
            raise UserNotFound
        return user

    async def current_user(self, user: Usuario) -> CurrentUser:
        return CurrentUser(
            usuario_id=user.usuario_id,
            nombre=f"{user.nombre} {user.apellido}",
            email=user.email,
            rol=user.roles[0].rol.nombre if user.roles else None,
            permisos=await self._repo.permission_names_for_user(user.usuario_id),
        )

    # --- usuarios (administracion) ---------------------------------------

    async def list_users(
        self,
        params: PageParams,
        *,
        q: str | None,
        rol: str | None,
        estado: str | None,
    ) -> tuple[list[Usuario], int]:
        return await self._repo.list_users(
            q=q, rol=rol, estado=estado, offset=params.offset, limit=params.page_size
        )

    async def create_user(
        self,
        actor: CurrentUser,
        nombre_completo: str,
        email: str,
        rol: str,
        password: str | None,
    ) -> tuple[Usuario, str | None]:
        temporary = None if password else secrets.token_urlsafe(9)
        user = await self._create_account(
            nombre_completo, email, password or temporary or "", rol
        )
        await self._audit.record(
            actor.usuario_id,
            "usuarios.crear",
            f"{user.nombre} {user.apellido}",
            tabla="usuario",
            id_registro=user.usuario_id,
            despues={"rol": rol},
        )
        await self._repo.commit()
        return user, temporary

    async def register_entrepreneur(
        self,
        actor: CurrentUser,
        nombre_completo: str,
        email: str,
        documento_identidad: str,
        password: str | None,
        *,
        commit: bool = True,
    ) -> tuple[Usuario, str | None]:
        """CU04: cuenta + perfil de emprendedor + documento, todo o nada.

        El documento se comprueba antes de crear nada; el commit es uno solo.
        Con `commit=False` solo hace flush: quien llama cierra la transaccion
        (lo usa la admision, CU26, para crear cuenta y emprendimiento juntos).
        """
        await self._entrepreneurs.ensure_document_free(documento_identidad)
        temporary = None if password else secrets.token_urlsafe(9)
        user = await self._create_account(
            nombre_completo, email, password or temporary or "", DEFAULT_ROLE
        )
        await self._entrepreneurs.set_document(user.usuario_id, documento_identidad)
        await self._audit.record(
            actor.usuario_id,
            "usuarios.crear",
            f"{user.nombre} {user.apellido}",
            tabla="usuario",
            id_registro=user.usuario_id,
            despues={"rol": DEFAULT_ROLE, "origen": "registro de emprendedor"},
        )
        if commit:
            await self._repo.commit()
        else:
            await self._repo.flush()
        return user, temporary

    async def change_role(
        self, actor: CurrentUser, usuario_id: int, rol: str
    ) -> Usuario:
        user = await self.get_user(usuario_id)
        role = await self._repo.get_role_by_name(rol)
        if role is None:
            raise RoleNotFound
        if usuario_id == actor.usuario_id and rol != ADMIN_ROLE:
            raise CannotDisableSelf
        before = user.roles[0].rol.nombre if user.roles else None
        await self._repo.set_user_role(user, role.rol_id)
        if rol == DEFAULT_ROLE:
            await self._entrepreneurs.create_profile(usuario_id)
        await self._audit.record(
            actor.usuario_id,
            "usuarios.cambiar_rol",
            f"{user.nombre} {user.apellido}",
            tabla="usuario",
            id_registro=usuario_id,
            antes={"rol": before},
            despues={"rol": rol},
        )
        await self._repo.commit()
        return await self.get_user(usuario_id)

    async def change_password(
        self, usuario_id: int, current: str, new: str
    ) -> tuple[Usuario, str, int]:
        """Cambia la clave e invalida todos los tokens anteriores.

        Devuelve un token nuevo para que el cliente que la cambio siga con sesion.
        """
        user = await self.get_user(usuario_id)
        if not verify_password(current, user.password_hash):
            raise WrongCurrentPassword
        await self._repo.set_password(user, hash_password(new))
        await self._audit.record(
            usuario_id, "usuarios.cambiar_clave", f"{user.nombre} {user.apellido}"
        )
        await self._repo.commit()
        token, expires_in = create_access_token(user.usuario_id)
        return user, token, expires_in

    async def request_password_reset(
        self, email: str, mailer: Mailer, ip: str | None = None
    ) -> None:
        """Envia un codigo de 6 digitos al correo si la cuenta existe y esta habilitada.

        No revela si la cuenta existe: el llamador responde igual en ambos casos.
        """
        email = email.strip().lower()
        key = f"reset|{ip or '-'}|{email}"
        if self._reset_limiter:
            if self._reset_limiter.is_blocked(key):
                raise TooManyRequests(
                    "Demasiadas solicitudes. Intenta de nuevo mas tarde.",
                    details={"retry_after": self._reset_limiter.retry_after(key)},
                )
            self._reset_limiter.hit(key)
        user = await self._repo.get_user_by_email(email)
        if user is None or user.estado == DISABLED:
            return
        settings = get_settings()
        code = f"{secrets.randbelow(10**6):06d}"
        await self._repo.invalidate_resets(user.usuario_id)
        await self._repo.add_reset(
            RestablecimientoPassword(
                usuario_id=user.usuario_id,
                codigo_hash=hash_password(code),
                expira=datetime.now(UTC)
                + timedelta(minutes=settings.reset_code_ttl_minutes),
            )
        )
        await self._repo.commit()
        await mailer.send(
            user.email,
            "Código para restablecer tu contraseña",
            f"Hola {user.nombre},\n\nTu código para restablecer la contraseña de "
            f"EmprendeU es: {code}\n\nVence en {settings.reset_code_ttl_minutes} "
            "minutos. Si no lo pediste, ignora este mensaje.",
        )

    async def reset_password(self, email: str, code: str, new: str) -> None:
        """Cambia la clave con el codigo recibido e invalida los tokens anteriores."""
        user = await self._repo.get_user_by_email(email.strip().lower())
        reset = (
            await self._repo.active_reset(user.usuario_id, datetime.now(UTC))
            if user is not None and user.estado != DISABLED
            else None
        )
        # Se verifica siempre (con hash falso si no hay codigo) para igualar tiempos.
        valid = verify_password(code, reset.codigo_hash if reset else None)
        if user is None or reset is None:
            raise InvalidResetCode
        if not valid:
            reset.intentos += 1
            if reset.intentos >= get_settings().reset_max_attempts:
                reset.usado = True
            await self._repo.commit()
            raise InvalidResetCode
        reset.usado = True
        await self._repo.set_password(user, hash_password(new))
        await self._audit.record(
            user.usuario_id,
            "usuarios.restablecer_clave",
            f"{user.nombre} {user.apellido}",
        )
        await self._repo.commit()

    async def mentors(self) -> list[Usuario]:
        """Usuarios con rol asesor y cuenta habilitada (para el modulo mentoring)."""
        return await self._repo.list_by_role("asesor")

    async def names_by_ids(self, ids: list[int]) -> dict[int, str]:
        return await self._repo.names_by_ids(ids)

    async def stats(self) -> dict[str, int]:
        """Totales por rol/estado para el resumen del panel."""
        return await self._repo.stats()

    async def set_estado(
        self, actor: CurrentUser, usuario_id: int, estado: str
    ) -> Usuario:
        if estado == DISABLED and usuario_id == actor.usuario_id:
            raise CannotDisableSelf
        user = await self._repo.get_user(usuario_id)
        if user is None:
            raise UserNotFound
        await self._repo.set_estado(user, estado)
        await self._audit.record(
            actor.usuario_id,
            "usuarios.habilitar" if estado == ENABLED else "usuarios.deshabilitar",
            f"{user.nombre} {user.apellido}",
            tabla="usuario",
            id_registro=usuario_id,
            antes={"estado": DISABLED if estado == ENABLED else ENABLED},
            despues={"estado": estado},
        )
        await self._repo.commit()
        return user

    async def _create_account(
        self, nombre_completo: str, email: str, password: str, rol: str
    ) -> Usuario:
        email = email.strip().lower()
        nombre, apellido = split_full_name(nombre_completo)
        role = await self._repo.get_role_by_name(rol)
        if role is None:
            raise RoleNotFound
        if await self._repo.get_user_by_email(email) is not None:
            raise EmailAlreadyRegistered
        usuario = Usuario(
            nombre=nombre,
            apellido=apellido,
            email=email,
            password_hash=hash_password(password),
            estado=ENABLED,
        )
        try:
            created = await self._repo.add_user(usuario, role.rol_id)
            if rol == DEFAULT_ROLE:
                await self._entrepreneurs.create_profile(created.usuario_id)
            await self._repo.flush()
        except IntegrityError as exc:  # carrera con otro alta del mismo correo
            await self._repo.rollback()
            raise EmailAlreadyRegistered from exc
        return created

    # --- roles y permisos -------------------------------------------------

    async def list_roles(self) -> list[tuple[Rol, int]]:
        return await self._repo.list_roles_with_counts()

    async def get_role_matrix(self, rol_id: int) -> dict[str, list[str]]:
        if await self._repo.get_role(rol_id) is None:
            raise RoleNotFound
        names = await self._repo.permission_names_for_role(rol_id)
        return {
            module: [a for a in ACTIONS if permission_name(module, a) in names]
            for module in MODULES
        }

    async def set_role_matrix(
        self, actor: CurrentUser, rol_id: int, matrix: dict[str, list[str]]
    ) -> dict[str, list[str]]:
        role = await self._repo.get_role(rol_id)
        if role is None:
            raise RoleNotFound
        names = {
            permission_name(m, a) for m, actions in matrix.items() for a in actions
        }
        unknown = names - ALL_PERMISSIONS
        if unknown:
            raise InvalidPermissions(
                "Permisos desconocidos.", details={"desconocidos": sorted(unknown)}
            )
        if role.nombre == ADMIN_ROLE and not ADMIN_REQUIRED <= names:
            raise AdminLockout
        before = sorted(await self._repo.permission_names_for_role(rol_id))
        await self._repo.replace_role_permissions(rol_id, frozenset(names))
        await self._audit.record(
            actor.usuario_id,
            "roles.modificar_permisos",
            f"Rol {role.nombre}",
            tabla="rol",
            id_registro=rol_id,
            antes={"permisos": before},
            despues={"permisos": sorted(names)},
        )
        await self._repo.commit()
        return await self.get_role_matrix(rol_id)

    # --- CRUD de roles ------------------------------------------------------

    async def create_role(
        self,
        actor: CurrentUser,
        nombre: str,
        descripcion: str | None,
        clonar_de: int | None,
    ) -> Rol:
        if await self._repo.get_role_by_name(nombre) is not None:
            raise RoleNameTaken
        names: frozenset[str] = frozenset()
        if clonar_de is not None:
            if await self._repo.get_role(clonar_de) is None:
                raise RoleNotFound
            names = await self._repo.permission_names_for_role(clonar_de)
        try:
            role = await self._repo.create_role(nombre, descripcion)
        except IntegrityError as exc:  # carrera con otra creacion del mismo nombre
            await self._repo.rollback()
            raise RoleNameTaken from exc
        await self._repo.replace_role_permissions(role.rol_id, names)
        await self._audit.record(
            actor.usuario_id,
            "roles.crear",
            f"Rol {nombre}",
            tabla="rol",
            id_registro=role.rol_id,
            antes=None,
            despues={"permisos": sorted(names), "clonar_de": clonar_de},
        )
        await self._repo.commit()
        return role

    async def edit_role(
        self,
        actor: CurrentUser,
        rol_id: int,
        nombre: str | None,
        descripcion: str | None,
    ) -> Rol:
        role = await self._repo.get_role(rol_id)
        if role is None:
            raise RoleNotFound
        if role.nombre in SYSTEM_ROLES:
            raise SystemRoleProtected
        if nombre is not None and nombre != role.nombre:
            if await self._repo.get_role_by_name(nombre) is not None:
                raise RoleNameTaken
        before = {"nombre": role.nombre, "descripcion": role.descripcion}
        await self._repo.update_role(role, nombre, descripcion)
        await self._audit.record(
            actor.usuario_id,
            "roles.editar",
            f"Rol {role.nombre}",
            tabla="rol",
            id_registro=rol_id,
            antes=before,
            despues={"nombre": role.nombre, "descripcion": role.descripcion},
        )
        await self._repo.commit()
        return role

    async def delete_role(self, actor: CurrentUser, rol_id: int) -> None:
        role = await self._repo.get_role(rol_id)
        if role is None:
            raise RoleNotFound
        if role.nombre in SYSTEM_ROLES:
            raise SystemRoleProtected
        if await self._repo.count_role_users(rol_id) > 0:
            raise RoleInUse
        name = role.nombre
        before = sorted(await self._repo.permission_names_for_role(rol_id))
        await self._repo.delete_role(role)
        await self._audit.record(
            actor.usuario_id,
            "roles.eliminar",
            f"Rol {name}",
            tabla="rol",
            id_registro=rol_id,
            antes={"nombre": name, "permisos": before},
            despues=None,
        )
        await self._repo.commit()
