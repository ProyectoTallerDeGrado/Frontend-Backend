"""Esquemas Pydantic de entrada y salida del modulo users."""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING, Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, StringConstraints

if TYPE_CHECKING:
    from emprendeu.modules.users.models import Usuario

Email = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        to_lower=True,
        max_length=254,
        pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
    ),
]
FullName = Annotated[
    str, StringConstraints(strip_whitespace=True, min_length=1, max_length=280)
]
Password = Annotated[str, Field(min_length=8, max_length=128)]
Estado = Literal["habilitada", "deshabilitada"]
Action = Literal["consulta", "registro", "modificacion", "administrativo"]


class LoginRequest(BaseModel):
    email: Email
    password: Annotated[str, Field(min_length=1, max_length=128)]


class RegisterRequest(BaseModel):
    nombre_completo: FullName
    email: Email
    password: Password


class UserCreate(BaseModel):
    nombre_completo: FullName
    email: Email
    rol: str
    # Si se omite, el servidor genera una temporal y la devuelve una sola vez.
    password: Password | None = None


class RoleUpdate(BaseModel):
    rol: str


class ForgotPasswordRequest(BaseModel):
    email: Email


class ResetPasswordRequest(BaseModel):
    email: Email
    codigo: Annotated[str, Field(pattern=r"^\d{6}$")]
    password_nueva: Password


class MessageResponse(BaseModel):
    mensaje: str


class PasswordChange(BaseModel):
    password_actual: Annotated[str, Field(min_length=1, max_length=128)]
    password_nueva: Password


class EstadoUpdate(BaseModel):
    estado: Estado


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    usuario_id: int
    nombre: str
    apellido: str
    email: str
    telefono: str | None
    estado: str | None
    rol: str | None
    ultimo_acceso: datetime | None
    fecha_registro: datetime | None

    @classmethod
    def from_model(cls, usuario: Usuario) -> UserOut:
        return cls(
            usuario_id=usuario.usuario_id,
            nombre=usuario.nombre,
            apellido=usuario.apellido,
            email=usuario.email,
            telefono=usuario.telefono,
            estado=usuario.estado,
            rol=usuario.roles[0].rol.nombre if usuario.roles else None,
            ultimo_acceso=usuario.ultimo_acceso,
            fecha_registro=usuario.fecha_registro,
        )


class CurrentUserOut(UserOut):
    permisos: list[str]


class TokenResponse(BaseModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"
    expires_in: int
    user: CurrentUserOut


class UserCreated(UserOut):
    temporary_password: str | None = None


class RoleOut(BaseModel):
    rol_id: int
    nombre: str
    descripcion: str | None
    total_usuarios: int


RoleName = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True,
        to_lower=True,
        min_length=3,
        max_length=60,
        pattern=r"(?i)^[a-z0-9][a-z0-9 _-]*$",
    ),
]
RoleDescription = Annotated[
    str, StringConstraints(strip_whitespace=True, max_length=300)
]


class RoleCreate(BaseModel):
    nombre: RoleName
    descripcion: RoleDescription | None = None
    clonar_de: int | None = None


class RoleEdit(BaseModel):
    nombre: RoleName | None = None
    descripcion: RoleDescription | None = None


class PermissionMatrix(BaseModel):
    """`{"usuarios": ["consulta", "registro"], "ia": []}`; lo omitido es sin acceso."""

    permisos: dict[str, list[Action]]
