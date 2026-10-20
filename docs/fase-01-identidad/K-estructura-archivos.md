# K — Estructura de archivos

Leyenda: **N** = archivo nuevo, **M** = modificación de un archivo existente,
**AG** = requiere actualizar el `AGENTS.md` del proyecto en el mismo commit
(regla global §4.4). Todo es **[P]**.

## 1. Backend (`Backend/EmprendeU/src/emprendeu/`)

### 1.1 `core/`

| Archivo | | Responsabilidad |
|---|---|---|
| `config.py` | M | Campos nuevos: `jwt_signing_keys: dict[str, SecretStr]`, `jwt_active_kid`, `jwt_issuer`, `jwt_audience`, `jwt_leeway_seconds=10`, `access_token_ttl_seconds=900`, `refresh_idle_web/mobile`, `session_absolute_web/mobile`, `refresh_reuse_grace_seconds=10`, `auth_hmac_key: SecretStr`, los límites de login y de reset, `password_min_length=12`, `invitation_ttl_hours=72`, `reset_ttl_minutes=30`, `hash_concurrency=4`, `trusted_proxies: list[IPv4Network\|IPv6Network]`, `app_public_url`, `mail_backend`, `mail_from` y `smtp_*`. Validadores: longitud de las claves y prohibición de `mail_backend=file` en producción. **Ningún secreto tiene valor por defecto.** |
| `errors.py` | M | `DomainError.headers: dict[str, str] \| None`; las clases genéricas `UnauthorizedError` (401), `ForbiddenError` (403) y `TooManyRequestsError` (429); el handler de validación **quita `input` y `ctx`** de `exc.errors()` (G §0.3). |
| `security.py` | N | `PasswordHasher` (pwdlib Argon2id + `anyio.to_thread` con un `CapacityLimiter`, `verify_and_update`, `dummy_verify`); `JwtKeyring` (firma con el `kid` activo y verifica según E-H §4.3); `new_opaque_token(prefix)`, `sha256_hex`, `hmac_hex` y `constant_time_equals`. Sin BD y sin `modules`. |
| `authz.py` | N | `Principal`, `Scope`, `VentureScopeResolver`, `PrincipalResolver`, `configure_authorization`, `get_principal`, `CurrentPrincipal`, `require_permissions`, `require_scope` y `VentureFilter` (C-D §11). Sin `modules`. |
| `pagination.py` | N | `PageParams` (validado) y `Page[T]` genérico, con la forma del contrato §5. |
| `logging.py` | N | Configuración de `structlog` (JSON en producción, consola en desarrollo) y el procesador de redacción (E-H §7). |
| `mail.py` | N, **AG** | Protocolo `MailSender` y los *backends* `SmtpMailSender` (stdlib `smtplib` + `anyio.to_thread`; **sin dependencias nuevas**), `FileMailSender` (solo en desarrollo; escribe `.eml` en un directorio fuera del repositorio) y `MemoryMailSender` (tests). |

### 1.2 `shared/`, `db/`, `api/` y `main.py`

| Archivo | | Responsabilidad |
|---|---|---|
| `shared/__init__.py` | N | Paquete (ya previsto en el AGENTS). |
| `shared/client_context.py` | N | `ClientContext(ip, user_agent)` y `client_context_from(request, trusted_proxies)` (E-H §7). |
| `db/metadata.py` | M | Importar `auth`. |
| `db/migrations/versions/<rev>_seed_roles_y_permisos.py` | N | E-H §1.3 #1. |
| `db/migrations/versions/<rev>_usuario_estado_y_email_normalizado.py` | N | #2 (solo con aprobación R-05). |
| `db/migrations/versions/<rev>_tablas_de_sesiones_y_tokens.py` | N | #3. |
| `db/migrations/versions/<rev>_fecha_de_salida_de_miembros.py` | N | #4 (solo si se aprueba N-17). |
| `api/v1.py` | M | `include_router` de `auth`, `users` (`/users`, `/roles`, `/permissions`) y `audit`; `configure_authorization(app)` con los resolvedores de los módulos. |
| `main.py` | M | Llamar a `configure_logging()` y a `configure_authorization`; nada de lógica. |

### 1.3 `modules/auth/` (módulo nuevo, **AG**: tabla §3b del AGENTS backend)

| Archivo | Responsabilidad |
|---|---|
| `__init__.py` | API pública: `router`, `resolve_principal`. |
| `models.py` | `SesionUsuario`, `TokenRefresco`, `TokenCuenta`, `IntentoLogin` (E-H §2), con todos los constraints con nombre en `__table_args__`. |
| `schemas.py` | `LoginIn`, `RefreshIn`, `LogoutIn`, `TokenPairOut`, `LoginOut`, `MeOut`, `MeUpdateIn`, `SessionOut`, `ChangePasswordIn`, `ForgotPasswordIn`, `ResetPasswordIn`, `AcceptInvitationIn`, `AdminRevokeSessionsIn`. Todos con `extra="forbid"`. |
| `repository.py` | Las consultas de sesiones, tokens de refresco, tokens de cuenta e intentos: `FOR UPDATE`, revocaciones masivas, conteos por ventana y purga. |
| `service.py` | `AuthService`: `login`, `refresh`, `logout`, `logout_all`, `me`, `list_sessions`, `revoke_session`, `change_password`, `forgot_password`, `reset_password`, `accept_invitation`, `issue_invitation`, `admin_reset`, `admin_list_sessions`, `admin_revoke_sessions` y `resolve_principal`. Usa `users` y `audit` a través de sus `__init__`. |
| `password_policy.py` | `validate_password(pw, *, email, nombre, apellido, current_hash?) -> list[Reason]` (B §5.2). Es pura y testeable aparte. **AG** (tipo de archivo nuevo en un módulo). |
| `data/common_passwords.txt` | La lista de bloqueo (≈1000 entradas), con su fuente documentada en la cabecera del archivo. **AG**. |
| `notifications.py` | Plantillas en texto plano de invitación, restablecimiento, aviso de cambio y aviso de cambio de correo; usa `core.mail`. **AG**. |
| `dependencies.py` | `get_auth_service`, `get_client_context`. |
| `exceptions.py` | `InvalidCredentials`, `AccountDisabled`, `TooManyAttempts`, `InvalidRefreshToken`, `RefreshSuperseded`, `TokenExpired`, `InvalidToken`, `SessionRevoked`, `NotAuthenticated`, `InvalidCurrentPassword`, `WeakPassword`, `InvalidOrExpiredToken` (derivadas de `core.errors`). |
| `router.py` | Los endpoints de G §1. |
| `cli.py` | `create-admin` y `purge`. **AG**. |
| `tests/` | Pruebas de servicio, repositorio, política de contraseñas y CLI. |

### 1.4 `modules/users/`

| Archivo | Responsabilidad |
|---|---|
| `__init__.py` | API pública: `router`, `catalog_router`, `UserService` y los tipos `Identity` y `Permission`. |
| `models.py` | **Sin cambios** salvo `Usuario.estado` y `Permiso.descripcion`, si se aprueba la migración #2. |
| `permissions.py` | `StrEnum Permission` (los códigos de C §3) y `StrEnum RoleCode`. Solo los **códigos**: el mapeo de rol a permiso vive en la BD. **AG**. |
| `policies.py` | `can_manage(actor_perms, target_roles)`, `assert_not_self`, `required_status_permission(from, to)` y `assert_valid_transition`. Funciones puras. **AG**. |
| `schemas.py` | `UserOut`, `UserCreateIn`, `UserUpdateIn`, `UserStatusIn`, `RoleAssignIn`, `RoleOut`, `PermissionOut`, `EffectivePermissionOut`, `UserListParams`. |
| `repository.py` | El CRUD de `usuario`, `rol_usuario`, `rol` y `permiso`; los permisos efectivos; el conteo de administradores activos con `FOR UPDATE`. |
| `service.py` | `UserService`. Para `auth`: `find_for_login`, `get_identity`, `set_password_hash`, `activate`, `get_roles`. Para la administración: `list`, `get`, `create`, `update`, `change_status`, `assign_role`, `revoke_role` y `effective_permissions`. Para `entrepreneurs`: `create_user`. |
| `dependencies.py` | `get_user_service`. |
| `exceptions.py` | `EmailTaken`, `LastAdmin`, `LastRole`, `InvalidStatusTransition` y `SelfManagementForbidden`. |
| `router.py` | `router` (`/users`) y `catalog_router` (`/roles`, `/permissions`). |
| `tests/` | — |

**Por qué el alta y la invitación son dos llamadas.** El token de invitación es de
`auth` (`token_cuenta`), y `auth` depende de `users`. Si `users` emitiera la invitación,
la dependencia sería circular (`users ↔ auth`). La cuenta `pendiente` sin invitación es
inofensiva, porque no puede iniciar sesión, y la UI ofrece reenviarla (G §2.2).

### 1.5 `modules/audit/`

| Archivo | Responsabilidad |
|---|---|
| `__init__.py` | API pública: `AuditService` y `router`. |
| `schemas.py` | `AuditEventOut`, `AuditQueryParams`. |
| `repository.py` | `insert` y una consulta paginada con filtros. |
| `service.py` | `record(actor_id, accion, tabla, id_registro, antes, despues, ip)`: aplica una **lista blanca** de claves y descarta cualquier clave que coincida con la lista de redacción (E-H §7). `query(params)`. |
| `router.py` | `GET /audit/events`. |
| `tests/` | — |

### 1.6 `modules/mentoring/` y `modules/entrepreneurs/`: solo los resolvedores de alcance

| Archivo | Responsabilidad |
|---|---|
| `mentoring/repository.py` | `assigned_venture_ids(usuario_id, venture_id) -> Select` (la consulta de C-D §7.1). |
| `mentoring/service.py` | La fachada del resolvedor (`MentoringScopes.assigned`). |
| `entrepreneurs/repository.py` | `member_venture_ids(usuario_id, venture_id) -> Select` (C-D §7.2). |
| `entrepreneurs/service.py` | La fachada del resolvedor. |
| `__init__.py` de cada uno | Exportar el resolvedor. |

> **Tensión con la regla global §4.5 (decisión N-28).** Estos `repository.py` y
> `service.py` nacen con **una sola** operación cada uno. No están vacíos ni a medio
> hacer para su uso, pero el CRUD de esos módulos llegará en otra fase. **Se recomienda**
> aceptarlo como una capa completa para la funcionalidad de alcance. La alternativa es
> posponer los flujos I-17…I-20 hasta las fases de `mentoring` y `entrepreneurs`.

**Pruebas de autorización por emprendimiento sin endpoints de negocio:** se usa
`tests/authz/test_venture_scope.py`, con una app FastAPI de prueba que registra la ruta
`GET /_probe/ventures/{id}` con `require_scope("ventures.read")`. Solo existe en
`tests/`, nunca en `api/v1.py`.

### 1.7 `tests/` (raíz del backend; integración de la API)

`conftest.py` (una BD PostgreSQL real con `alembic upgrade head`, transacción por test,
`MemoryMailSender` y reloj controlable), `test_auth_api.py`, `test_users_api.py`,
`test_roles_api.py`, `test_audit_api.py`, `authz/test_venture_scope.py`,
`test_permission_catalog.py` (el enum frente a la BD) y `test_openapi_contract.py` (las
rutas y los códigos de error documentados).

> Las pruebas necesitan **PostgreSQL**: `FOR UPDATE`, los índices parciales y `now()`
> no se pueden simular con SQLite. Que haya un PostgreSQL disponible en CI o en local
> **no está verificado** (N-29).

### 1.8 Otros archivos

| Archivo | | Cambio |
|---|---|---|
| `.env.example` | M | Las variables nuevas, con los secretos **vacíos** y el comando para generarlos. |
| `Backend/EmprendeU/AGENTS.md` | M | El módulo `auth` en §3b; `core/authz.py`, `core/mail.py` y `shared/client_context.py` en §3; los archivos `policies.py`, `permissions.py`, `password_policy.py`, `notifications.py`, `cli.py` y `data/` como opcionales del módulo; actualizar "Estado real". |
| `pyproject.toml` | — | **Sin dependencias nuevas.** |

## 2. Web (`Frontend/emprendeu/`)

```
proxy.ts                                   N  renovación de la sesión (E-H §5.3)
app/
├── (public)/
│   ├── layout.tsx                         N  layout centrado, sin navegación
│   ├── login/page.tsx                     N  → features/auth LoginScreen
│   ├── forgot-password/page.tsx           N
│   ├── reset-password/page.tsx            N  Referrer-Policy: no-referrer (metadata/headers)
│   ├── activate/page.tsx                  N  aceptar la invitación
│   └── session-expired/page.tsx           N
├── (app)/
│   ├── layout.tsx                         N  getSession() → redirect('/login'); AppShell
│   ├── forbidden.tsx                      N  si se aprueba authInterrupts (N-16); si no, forbidden/page.tsx
│   ├── page.tsx                           N  inicio según permisos
│   ├── profile/page.tsx                   N
│   └── admin/
│       ├── users/page.tsx                 N
│       ├── users/new/page.tsx             N
│       ├── users/[userId]/page.tsx        N
│       ├── users/[userId]/edit/page.tsx   N
│       ├── users/[userId]/roles/page.tsx  N
│       ├── roles/page.tsx                 N
│       └── permissions/page.tsx           N
├── layout.tsx                             M  metadata, idioma "es"
└── page.tsx                               M  redirección a /login o a (app)
features/
├── auth/
│   ├── components/  LoginForm, ForgotPasswordForm, SetPasswordForm (reset y activación),
│   │                SessionExpiredNotice, ChangePasswordForm, SessionsList, PermissionGate
│   ├── server/      session.ts (getSession, requireSession, requirePermission),
│   │                actions.ts (login, logout, logoutAll, changePassword, forgotPassword,
│   │                            resetPassword, acceptInvitation, revokeSession),
│   │                cookies.ts (set/clear de __Host-eu_at / __Host-eu_rt),
│   │                refresh.ts (lógica que invoca proxy.ts)
│   ├── schemas/     login.ts, password.ts, me.ts (zod de las respuestas del backend)
│   ├── types.ts
│   └── index.ts
└── users/
    ├── components/  UsersTable, UsersFilters, UserForm, UserDetail, UserStatusDialog,
    │                RoleAssignment, EffectivePermissions, RolesCatalog, PermissionsCatalog
    ├── server/      queries.ts (listUsers, getUser, listRoles, listPermissions, getEffectivePermissions),
    │                actions.ts (createUser, updateUser, changeStatus, assignRole, revokeRole,
    │                            sendInvitation, sendPasswordReset, revokeUserSessions)
    ├── schemas/     user.ts, role.ts, permission.ts
    ├── types.ts
    └── index.ts
components/layout/   AppShell, Sidebar (navegación derivada de los permisos), UserMenu, PageHeader
components/ui/       primitivas shadcn a añadir: input, label, card, table, dialog, alert-dialog,
                     badge, dropdown-menu, select, checkbox, tabs, sonner, skeleton, separator,
                     avatar, tooltip, pagination
lib/
├── api-client.ts    N  fetch server-only al backend; parsea {"error":{...}} a ApiError
├── env.ts           N  zod de API_BASE_URL, APP_ORIGIN, la política de cookies
└── security.ts      N  assertSameOrigin (E-H §5.4), safeNextPath
```

- Dependencia nueva: **`zod`**, ya prevista en el `AGENTS.md` de la web.
- La navegación de `users` y `auth` comparte el nombre de dominio con los módulos del
  backend (regla 6). Las pantallas de roles y permisos viven en la feature `users`,
  porque su módulo de backend es `users`.
- `proxy.ts` importa `refreshInProxy` desde `@/features/auth` (el barrel). Que el barrel
  no arrastre componentes cliente a la ejecución del proxy **hay que comprobarlo** con
  `pnpm build`.
- **AG:** registrar `auth` y `users` en "Features previstas" y `lib/security.ts` en §3.

## 3. Móvil (`Frontend/app_emprendeu/lib/`)

```
app/router.dart                                   M  redirect según AuthState; rutas de auth
core/config/env.dart                              N  API_BASE_URL por --dart-define
core/network/dio_client.dart                      N  Dio base + AuthInterceptor + timeouts
core/network/auth_interceptor.dart                N  Bearer, 401 → refresh → un reintento
core/network/token_refresher.dart                 N  refresh single-flight (Dio sin el interceptor)
core/network/api_error.dart                       N  mapeo de {"error":{code,message,details}}
core/storage/secure_token_storage.dart            N  flutter_secure_storage (E-H §6.1)
core/error/failure.dart                           N
features/auth/data/datasources/auth_remote_data_source.dart   N
features/auth/data/models/{token_pair,me,session}_dto.dart    N  freezed + json_serializable
features/auth/data/repositories/auth_repository_impl.dart     N
features/auth/domain/entities/{auth_session,current_user}.dart N
features/auth/domain/repositories/auth_repository.dart        N
features/auth/domain/usecases/{login,logout,logout_all,refresh_session,get_me,
                               change_password,request_password_reset}.dart  N
features/auth/presentation/controllers/auth_controller.dart   N  Notifier<AuthState>
features/auth/presentation/screens/{splash,login,forgot_password,profile,sessions}_screen.dart N
features/auth/presentation/widgets/...                        N
features/auth/index.dart                                      N  API pública
```

- **[P]** El móvil **no** tiene pantallas de administración de usuarios: la
  administración solo se hace en la web.
- El restablecimiento de contraseña en el móvil abre el enlace del correo en el
  navegador (`/reset-password`). No se configuran *deep links* en esta fase.
- **AG:** actualizar el `AGENTS.md` del móvil: los paquetes ya están en `pubspec.yaml`
  (hallazgo de README §1.1) y hay que registrar la feature `auth`.
