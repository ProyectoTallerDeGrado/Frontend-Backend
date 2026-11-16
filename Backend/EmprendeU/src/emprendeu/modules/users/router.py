"""HTTP del modulo users: /auth, /users y /roles."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request, status

from emprendeu.core.client_ip import client_ip
from emprendeu.core.mailer import Mailer, get_mailer
from emprendeu.core.pagination import Page, PageParamsDep
from emprendeu.modules.users.dependencies import (
    CurrentUserDep,
    UserServiceDep,
    require_permission,
)
from emprendeu.modules.users.models import Usuario
from emprendeu.modules.users.permissions import (
    USERS_ADMIN,
    USERS_CREATE,
    USERS_READ,
    USERS_UPDATE,
)
from emprendeu.modules.users.schemas import (
    CurrentUserOut,
    EstadoUpdate,
    ForgotPasswordRequest,
    LoginRequest,
    MessageResponse,
    PasswordChange,
    PermissionMatrix,
    RegisterRequest,
    ResetPasswordRequest,
    RoleCreate,
    RoleEdit,
    RoleOut,
    RoleUpdate,
    TokenResponse,
    UserCreate,
    UserCreated,
    UserOut,
)
from emprendeu.modules.users.service import CurrentUser

router = APIRouter()
auth_router = APIRouter(prefix="/auth", tags=["auth"])
users_router = APIRouter(prefix="/users", tags=["users"])
roles_router = APIRouter(prefix="/roles", tags=["roles"])


def _current_out(user: Usuario, current: CurrentUser) -> CurrentUserOut:
    base = UserOut.from_model(user)
    return CurrentUserOut(**base.model_dump(), permisos=sorted(current.permisos))


@auth_router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest, service: UserServiceDep, request: Request
) -> TokenResponse:
    ip = client_ip(request)
    user, token, expires_in = await service.login(body.email, body.password, ip)
    current = await service.current_user(user)
    return TokenResponse(
        access_token=token,
        expires_in=expires_in,
        user=_current_out(user, current),
    )


@auth_router.post(
    "/forgot-password",
    response_model=MessageResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def forgot_password(
    body: ForgotPasswordRequest,
    service: UserServiceDep,
    request: Request,
    mailer: Annotated[Mailer, Depends(get_mailer)],
) -> MessageResponse:
    """Pide un codigo por correo. La respuesta es igual exista o no la cuenta."""
    ip = client_ip(request)
    await service.request_password_reset(body.email, mailer, ip)
    return MessageResponse(
        mensaje="Si el correo esta registrado, te enviamos un codigo de 6 digitos."
    )


@auth_router.post("/reset-password", response_model=MessageResponse)
async def reset_password(
    body: ResetPasswordRequest, service: UserServiceDep
) -> MessageResponse:
    """Cambia la clave con el codigo recibido; los tokens anteriores dejan de valer."""
    await service.reset_password(body.email, body.codigo, body.password_nueva)
    return MessageResponse(mensaje="Contrasena actualizada. Ya puedes iniciar sesion.")


@auth_router.post(
    "/register", response_model=UserOut, status_code=status.HTTP_201_CREATED
)
async def register(body: RegisterRequest, service: UserServiceDep) -> UserOut:
    user = await service.register(body.nombre_completo, body.email, body.password)
    return UserOut.from_model(user)


@auth_router.get("/me", response_model=CurrentUserOut)
async def me(current: CurrentUserDep, service: UserServiceDep) -> CurrentUserOut:
    user = await service.get_user(current.usuario_id)
    return _current_out(user, current)


@auth_router.post("/change-password", response_model=TokenResponse)
async def change_password(
    body: PasswordChange, current: CurrentUserDep, service: UserServiceDep
) -> TokenResponse:
    """Cambia la clave. Los tokens anteriores dejan de valer; se devuelve uno nuevo."""
    user, token, expires_in = await service.change_password(
        current.usuario_id, body.password_actual, body.password_nueva
    )
    return TokenResponse(
        access_token=token,
        expires_in=expires_in,
        user=_current_out(user, await service.current_user(user)),
    )


@users_router.get("", response_model=Page[UserOut])
async def list_users(
    params: PageParamsDep,
    service: UserServiceDep,
    _: Annotated[CurrentUser, Depends(require_permission(USERS_READ))],
    q: Annotated[str | None, Query(max_length=100)] = None,
    rol: str | None = None,
    estado: str | None = None,
) -> Page[UserOut]:
    users, total = await service.list_users(params, q=q, rol=rol, estado=estado)
    return Page[UserOut].build([UserOut.from_model(u) for u in users], params, total)


@users_router.post("", response_model=UserCreated, status_code=status.HTTP_201_CREATED)
async def create_user(
    body: UserCreate,
    service: UserServiceDep,
    actor: Annotated[CurrentUser, Depends(require_permission(USERS_CREATE))],
) -> UserCreated:
    user, temporary = await service.create_user(
        actor, body.nombre_completo, body.email, body.rol, body.password
    )
    return UserCreated(
        **UserOut.from_model(user).model_dump(), temporary_password=temporary
    )


@users_router.patch("/{usuario_id}/estado", response_model=UserOut)
async def update_estado(
    usuario_id: int,
    body: EstadoUpdate,
    service: UserServiceDep,
    actor: Annotated[CurrentUser, Depends(require_permission(USERS_UPDATE))],
) -> UserOut:
    user = await service.set_estado(actor, usuario_id, body.estado)
    return UserOut.from_model(user)


@users_router.patch("/{usuario_id}/rol", response_model=UserOut)
async def update_role(
    usuario_id: int,
    body: RoleUpdate,
    service: UserServiceDep,
    actor: Annotated[CurrentUser, Depends(require_permission(USERS_ADMIN))],
) -> UserOut:
    user = await service.change_role(actor, usuario_id, body.rol)
    return UserOut.from_model(user)


@roles_router.get("", response_model=list[RoleOut])
async def list_roles(
    service: UserServiceDep,
    _: Annotated[CurrentUser, Depends(require_permission(USERS_READ))],
) -> list[RoleOut]:
    return [
        RoleOut(
            rol_id=r.rol_id,
            nombre=r.nombre,
            descripcion=r.descripcion,
            total_usuarios=count,
        )
        for r, count in await service.list_roles()
    ]


@roles_router.get("/{rol_id}/permissions", response_model=PermissionMatrix)
async def get_permissions(
    rol_id: int,
    service: UserServiceDep,
    _: Annotated[CurrentUser, Depends(require_permission(USERS_READ))],
) -> PermissionMatrix:
    return PermissionMatrix(permisos=await service.get_role_matrix(rol_id))  # type: ignore[arg-type]


@roles_router.put("/{rol_id}/permissions", response_model=PermissionMatrix)
async def put_permissions(
    rol_id: int,
    body: PermissionMatrix,
    service: UserServiceDep,
    actor: Annotated[CurrentUser, Depends(require_permission(USERS_ADMIN))],
) -> PermissionMatrix:
    matrix = await service.set_role_matrix(actor, rol_id, body.permisos)  # type: ignore[arg-type]
    return PermissionMatrix(permisos=matrix)  # type: ignore[arg-type]


@roles_router.post("", response_model=RoleOut, status_code=status.HTTP_201_CREATED)
async def create_role(
    body: RoleCreate,
    service: UserServiceDep,
    actor: Annotated[CurrentUser, Depends(require_permission(USERS_ADMIN))],
) -> RoleOut:
    role = await service.create_role(
        actor, body.nombre, body.descripcion, body.clonar_de
    )
    return RoleOut(
        rol_id=role.rol_id,
        nombre=role.nombre,
        descripcion=role.descripcion,
        total_usuarios=0,
    )


@roles_router.patch("/{rol_id}", response_model=RoleOut)
async def edit_role(
    rol_id: int,
    body: RoleEdit,
    service: UserServiceDep,
    actor: Annotated[CurrentUser, Depends(require_permission(USERS_ADMIN))],
) -> RoleOut:
    role = await service.edit_role(actor, rol_id, body.nombre, body.descripcion)
    counts = {r.rol_id: c for r, c in await service.list_roles()}
    return RoleOut(
        rol_id=role.rol_id,
        nombre=role.nombre,
        descripcion=role.descripcion,
        total_usuarios=counts.get(role.rol_id, 0),
    )


@roles_router.delete("/{rol_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_role(
    rol_id: int,
    service: UserServiceDep,
    actor: Annotated[CurrentUser, Depends(require_permission(USERS_ADMIN))],
) -> None:
    await service.delete_role(actor, rol_id)


router.include_router(auth_router)
router.include_router(users_router)
router.include_router(roles_router)
