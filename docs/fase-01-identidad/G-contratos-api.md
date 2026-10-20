# G — Contratos API (`/api/v1`)

## 0. Convenciones

### 0.1 Generales [C] / [P]

- **[C]** Todas las rutas cuelgan de `/api/v1` (`settings.api_v1_prefix`). OpenAPI en
  `/api/v1/openapi.json`.
- **[P]** Request y response en `application/json; charset=utf-8`. Las fechas, en
  ISO-8601 UTC con `Z` (`2026-10-20T15:00:00Z`). Los IDs son números enteros.
- **[P] Nombres de campo:** los que corresponden a columnas de `cieu` conservan su
  nombre en español (`usuario_id`, `nombre`, `estado`), por la excepción de la regla
  global §4.9. Los campos de protocolo usan los nombres estándar en inglés
  (`access_token`, `token_type`, `refresh_token`).
- **[P]** Los valores de `client`/`tipo_cliente` en la API son `"web"` y `"mobile"`;
  el repositorio los traduce a `'web'`/`'movil'` en la BD.
- **[P]** `extra="forbid"` en todos los esquemas Pydantic de entrada: un campo
  desconocido → `422`. Así se evita la asignación masiva (p. ej., colar `"roles"`
  en `PATCH /users/{id}`).
- **[P]** Respuestas de endpoints autenticados: `Cache-Control: no-store`.
- **[P]** Paginación: `?page=1&page_size=20` (1 ≤ `page_size` ≤ 100) →
  `{"items": [...], "page": 1, "page_size": 20, "total": 57}`.

### 0.2 Cabeceras

| Cabecera | Dirección | Uso |
|---|---|---|
| `Authorization: Bearer <access JWT>` | → API | Todo endpoint marcado "Auth: sí". |
| `X-Forwarded-For` | BFF → API | IP del navegador; solo se acepta si viene de `TRUSTED_PROXIES` (E-H §7). |
| `User-Agent` | → API | Informativo (sesión). |
| `WWW-Authenticate: Bearer error="invalid_token"` | ← API | En todo `401` de un endpoint autenticado. |
| `Retry-After: <segundos>` | ← API | En `429`. |
| `Location` | ← API | En `201`. |

**Cookies:** la API **no** lee ni escribe cookies. En la web, el BFF convierte las
respuestas de login y refresh en las cookies `__Host-eu_at` y `__Host-eu_rt` (E-H §5.1),
y de esas cookies saca el `Bearer` y el `refresh_token` de las llamadas siguientes.

### 0.3 Errores

Formato único [C]: `{"error": {"code": str, "message": str, "details": object|null}}`.

| HTTP | `code` | Cuándo |
|---|---|---|
| 400 | `invalid_current_password` | `change-password` con la contraseña actual incorrecta. No es 401, para que el cliente no lo confunda con una sesión caducada. |
| 400 | `invalid_or_expired_token` | Token de invitación o restablecimiento inexistente, usado, invalidado o caducado. Un único código para no distinguir los casos. |
| 401 | `not_authenticated` | Falta `Authorization` o el esquema no es `Bearer`. |
| 401 | `invalid_token` | Firma, `kid`, claims o formato inválidos. |
| 401 | `token_expired` | El access token caducó: hay que renovar. |
| 401 | `session_revoked` | Sesión revocada o caducada, o cuenta no activa: hay que volver a iniciar sesión. |
| 401 | `invalid_credentials` | Login fallido (genérico). |
| 401 | `invalid_refresh_token` | Refresh inválido, caducado, revocado o reutilizado. |
| 403 | `account_disabled` | Login con la contraseña **correcta** de una cuenta `bloqueado`/`inactivo`. |
| 403 | `forbidden` | Ninguna variante del permiso exigido. |
| 403 | `self_management_forbidden` | Gestionar los roles o el estado propios. |
| 404 | `not_found` | Inexistente **o** fuera de alcance (C-D §9). |
| 409 | `email_taken` | El correo ya existe (comparado tras normalizarlo). |
| 409 | `last_admin` | Dejaría cero administradores activos. |
| 409 | `last_role` | Dejaría sin roles a un usuario activo. |
| 409 | `invalid_status_transition` | Transición no permitida (B §2.2). |
| 409 | `refresh_superseded` | Carrera de refresh dentro de la gracia (E-H §3.3). |
| 422 | `validation_error` | [C] Handler existente. `details` = `exc.errors()` **sin** `input` (para no devolver contraseñas): el handler actual debe filtrarlo (K §1). |
| 422 | `weak_password` | `details: {"reasons": ["too_short" \| "too_long" \| "common" \| "contains_personal_data" \| "same_as_current"]}` |
| 429 | `too_many_attempts` | Límite de login, forgot-password o reset. Con `Retry-After`. |

Los `message` van en español, se pueden mostrar al usuario y **nunca** incluyen
detalles internos, nombres de tabla ni trazas.

### 0.4 Eventos de auditoría (`bitacora.accion`) [P]

`auth.login.succeeded`, `auth.login.failed` (solo con una cuenta existente),
`auth.login.throttled`, `auth.login.null_password`, `auth.logout`, `auth.logout_all`,
`auth.session.revoked`, `auth.refresh.reuse_detected`, `auth.password.changed`,
`auth.password.reset_requested`, `auth.password.reset_completed`,
`auth.invitation.issued`, `auth.invitation.accepted`, `auth.admin.break_glass`,
`users.admin.bootstrap`, `users.created`, `users.updated`, `users.status.changed`,
`users.role.assigned`, `users.role.revoked`.

Los refresh exitosos **no** se auditan: actualizan `sesion_usuario` y, si no, generarían
ruido. Las lecturas no se auditan, salvo `reports.export` (en su fase).

### 0.5 Esquemas comunes

```jsonc
// UserOut
{
  "usuario_id": 42,
  "nombre": "Ana",
  "apellido": "Quispe",
  "email": "ana.quispe@universidad.edu",
  "telefono": "+591 70000000",
  "estado": "activo",
  "fecha_registro": "2026-10-01T13:00:00Z",
  "fecha_actualizacion": "2026-10-15T09:30:00Z",
  "roles": [{ "rol_id": 4, "nombre": "EMPRENDEDOR" }]
}
// RoleOut
{ "rol_id": 2, "nombre": "COORDINADOR", "descripcion": "Gestiona el programa", "permisos": ["ventures.read.all", "..."] }
// PermissionOut
{ "permiso_id": 17, "nombre": "ventures.read.all", "descripcion": "Ver cualquier emprendimiento." }
// SessionOut
{ "sid": "3f2b...", "client": "web", "fecha_creacion": "...", "fecha_ultimo_uso": "...",
  "fecha_expiracion": "...", "agente_usuario": "Mozilla/5.0 ...", "nombre_dispositivo": null,
  "ip_ultimo_uso": "190.0.2.10", "actual": true }
// TokenPair
{ "token_type": "Bearer",
  "access_token": "eyJ...", "access_token_expires_at": "2026-10-20T15:15:00Z",
  "refresh_token": "eurt_Q2x...", "refresh_token_expires_at": "2026-10-27T15:00:00Z" }
// MeOut
{ "user": UserOut, "permisos": ["users.read.all", "..."], "session": SessionOut }
```

Límites de entrada:

| Campo | Regla |
|---|---|
| `nombre` | 1–160 caracteres, sin espacios al borde y sin caracteres de control. |
| `apellido` | 1–120 caracteres, ídem. |
| `email` | ≤ 254; validación sintáctica (B §3); se normaliza. |
| `telefono` | ≤ 35; `^[+0-9 ()-]{6,35}$`. |
| `password` | Política de B §5.2. |
| `motivo` | 3–500 caracteres. |

---

## 1. Autenticación (`modules/auth`)

### 1.1 `POST /auth/login`

| | |
|---|---|
| Auth | No |
| Request | `{"email": str, "password": str, "client": "web"\|"mobile", "device_name": str?≤100}` |
| 200 | `TokenPair` + `"session": SessionOut`, `"user": UserOut`, `"permisos": [...]` |
| Errores | 401 `invalid_credentials` · 403 `account_disabled` · 422 · 429 `too_many_attempts` |
| Web | El BFF guarda `access_token` y `refresh_token` en cookies y **no** pasa los tokens al cliente React. |
| Móvil | `refresh_token` → secure storage; `access_token` → memoria. |
| Auditoría | `auth.login.succeeded` / `auth.login.failed` / `auth.login.throttled` |

Lógica: normalizar el correo → comprobar el límite (por `email_hmac` y por IP) **antes**
de verificar → buscar el usuario → verificar Argon2 (o el hash ficticio si no existe o
es NULL) → si la contraseña es correcta pero el estado no es `activo`: 403 → crear la
`sesion_usuario` y el `token_refresco` → registrar el intento → `verify_and_update`
(rehash).

```json
// 200
{ "token_type": "Bearer", "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "access_token_expires_at": "2026-10-20T15:15:00Z",
  "refresh_token": "eurt_8pV0...", "refresh_token_expires_at": "2026-10-27T15:00:00Z",
  "session": { "sid": "3f2b8c1e-...", "client": "web", "fecha_creacion": "2026-10-20T15:00:00Z",
               "fecha_ultimo_uso": null, "fecha_expiracion": "2026-11-19T15:00:00Z",
               "agente_usuario": "Mozilla/5.0", "nombre_dispositivo": null,
               "ip_ultimo_uso": "190.0.2.10", "actual": true },
  "user": { "usuario_id": 42, "nombre": "Ana", "...": "..." },
  "permisos": ["ventures.read.own", "documents.read.own"] }
// 401
{ "error": { "code": "invalid_credentials", "message": "Correo o contraseña incorrectos.", "details": null } }
```

Pruebas: T-AUTH-01…12 (M).

### 1.2 `POST /auth/refresh`

| | |
|---|---|
| Auth | No (el refresh es la credencial) |
| Request | `{"refresh_token": str ≤ 100, "client": "web"\|"mobile"}` |
| 200 | `TokenPair` (refresh **nuevo**; el anterior queda consumido) |
| Errores | 401 `invalid_refresh_token` · 409 `refresh_superseded` · 422 |
| Auditoría | Solo `auth.refresh.reuse_detected` |

Pruebas: T-SES-01…10.

### 1.3 `POST /auth/logout`

| | |
|---|---|
| Auth | Opcional. Si viene un `Bearer` válido, se revoca también su `sid`. |
| Request | `{"refresh_token": str}` |
| 204 | Siempre, aunque el token no sea válido (idempotente; no revela nada). |
| Auditoría | `auth.logout` (si había una sesión válida) |

### 1.4 `POST /auth/logout-all`

| | |
|---|---|
| Auth | Sí |
| Request | vacío |
| 204 | Revoca **todas** las sesiones del usuario, incluida la actual. |
| Auditoría | `auth.logout_all` con `datos_nuevos: {"sesiones_revocadas": n}` |

### 1.5 `GET /auth/me`

| | |
|---|---|
| Auth | Sí (implícito: cualquier cuenta activa) |
| 200 | `MeOut` |
| Errores | 401 |

```json
{ "user": { "usuario_id": 7, "nombre": "Luis", "apellido": "Rojas", "email": "luis@universidad.edu",
            "telefono": null, "estado": "activo", "fecha_registro": "2026-09-01T12:00:00Z",
            "fecha_actualizacion": null, "roles": [{ "rol_id": 3, "nombre": "MENTOR" }] },
  "permisos": ["entrepreneurs.read.assigned", "ventures.read.assigned", "..."],
  "session": { "sid": "...", "client": "mobile", "actual": true, "...": "..." } }
```

### 1.6 `PATCH /auth/me`

| | |
|---|---|
| Auth | Sí (implícito) |
| Request | `{"telefono": str\|null}`. Cualquier otro campo → 422 (N-27 decide si el usuario puede editar su nombre). |
| 200 | `UserOut` |
| Auditoría | `users.updated` (actor = el propio usuario) |

### 1.7 `POST /auth/change-password`

| | |
|---|---|
| Auth | Sí |
| Request | `{"current_password": str, "new_password": str}` |
| 204 | Se cambia el hash y se revocan **las demás** sesiones; la actual sigue. |
| Errores | 400 `invalid_current_password` · 422 `weak_password` · 429 (5 fallos de la actual en 15 min) |
| Auditoría | `auth.password.changed` |
| Notificación | Correo de aviso "Tu contraseña cambió". |

### 1.8 `POST /auth/password/forgot`

| | |
|---|---|
| Auth | No |
| Request | `{"email": str}` |
| 202 | `{"message": "Si el correo está registrado, recibirás instrucciones."}`. **Siempre** igual. |
| Errores | 422 (solo por formato; **nunca** 404) |
| Auditoría | `auth.password.reset_requested` solo si la cuenta existe. |

### 1.9 `POST /auth/password/reset`

| | |
|---|---|
| Auth | No |
| Request | `{"token": "euat_...", "new_password": str}` |
| 204 | Contraseña fijada, token consumido, **todas** las sesiones revocadas. Sin inicio de sesión automático. |
| Errores | 400 `invalid_or_expired_token` · 422 `weak_password` · 429 |
| Auditoría | `auth.password.reset_completed` |

### 1.10 `POST /auth/invitations/accept`

| | |
|---|---|
| Auth | No |
| Request | `{"token": "euat_...", "password": str}` |
| 204 | `usuario.estado: pendiente → activo` y contraseña fijada. Sin inicio de sesión automático. |
| Errores | 400 `invalid_or_expired_token` (también si la cuenta ya no está `pendiente`) · 422 `weak_password` · 429 |
| Auditoría | `auth.invitation.accepted` |

### 1.11 `GET /auth/sessions` · `DELETE /auth/sessions/{sid}`

| | |
|---|---|
| Auth | Sí (implícito: solo las propias) |
| GET 200 | `{"items": [SessionOut], "page", "page_size", "total"}`: solo las sesiones válidas. |
| DELETE 204 | Revoca la sesión `sid` si es del usuario. Si no existe o es de otro: 404. Revocar la actual equivale a un logout. |

### 1.12 Administración de credenciales y sesiones de otros

| Método y ruta | Permiso | Request | Respuesta | Notas |
|---|---|---|---|---|
| `POST /auth/users/{usuario_id}/invitation` | `users.credentials.reset` + dominancia | vacío | `202 {"message": "Invitación enviada."}` | El destino debe estar `pendiente` (si no, 409 `invalid_status_transition`). Invalida las invitaciones anteriores. Auditoría `auth.invitation.issued`. **El token no se devuelve** (N-10). |
| `POST /auth/users/{usuario_id}/password-reset` | `users.credentials.reset` + dominancia | vacío | `202` | El destino debe estar `activo`. Auditoría `auth.password.reset_requested` (actor = el administrador). |
| `GET /auth/users/{usuario_id}/sessions` | `users.sessions.read` + dominancia | — | `200 Page[SessionOut]` | `actual` siempre `false`. |
| `POST /auth/users/{usuario_id}/sessions/revoke` | `users.sessions.revoke` + dominancia | `{"motivo": str}` | `204` | `motivo_revocacion = revocacion_admin`, `revocada_por = actor`. Auditoría `auth.session.revoked`. |

Pruebas: T-ADM-20…26.

---

## 2. Usuarios (`modules/users`)

### 2.1 `GET /users`

| | |
|---|---|
| Permiso | `users.read.all` |
| Query | `page`, `page_size`, `q` (2–100 caracteres: nombre, apellido o correo; `ILIKE` con los comodines escapados), `estado`, `rol` (código), `sort` ∈ {`nombre`,`apellido`,`email`,`fecha_registro`} con prefijo `-` para orden descendente (por defecto `-fecha_registro`) |
| 200 | `Page[UserOut]` |
| Errores | 401 · 403 · 422 |

### 2.2 `POST /users`

| | |
|---|---|
| Permiso | `users.create` **y** `roles.assign.<r>` para cada `r` de `roles` |
| Request | `{"nombre", "apellido", "email", "telefono"?, "roles": ["MENTOR"]}` (1 a 4 roles, sin repetidos) |
| 201 | `UserOut` con `estado: "pendiente"`; `Location: /api/v1/users/{id}` |
| Errores | 403 `forbidden` (falta algún `roles.assign.*`) · 409 `email_taken` · 422 |
| Auditoría | `users.created` (+ `users.role.assigned` por rol) |
| Siguiente paso | El cliente llama a `POST /auth/users/{id}/invitation`. En la web, la misma Server Action hace las dos llamadas. Si la segunda falla, la UI muestra "Usuario creado; reintentar envío de invitación" (K §1.4 explica por qué son dos llamadas). |

```json
// request
{ "nombre": "Carla", "apellido": "Mamani", "email": "Carla.Mamani@Universidad.edu", "roles": ["EMPRENDEDOR"] }
// 201
{ "usuario_id": 58, "nombre": "Carla", "apellido": "Mamani", "email": "carla.mamani@universidad.edu",
  "telefono": null, "estado": "pendiente", "fecha_registro": "2026-10-20T15:02:11Z",
  "fecha_actualizacion": null, "roles": [{ "rol_id": 4, "nombre": "EMPRENDEDOR" }] }
```

### 2.3 `GET /users/{usuario_id}`

Permiso `users.read.all` → `200 UserOut`, o `404`.

### 2.4 `PATCH /users/{usuario_id}`

| | |
|---|---|
| Permiso | `users.update` + dominancia; no a uno mismo (para eso está `PATCH /auth/me`) |
| Request | Cualquier subconjunto de `{"nombre", "apellido", "telefono", "email"}`; **al menos un** campo |
| 200 | `UserOut` |
| Efectos | Si cambia `email`: revoca todas sus sesiones (`cambio_email`), invalida sus tokens de cuenta y avisa al correo **anterior**. |
| Errores | 403 · 404 · 409 `email_taken` · 422 |
| Auditoría | `users.updated` con solo los campos cambiados |

### 2.5 `POST /users/{usuario_id}/status`

| | |
|---|---|
| Permiso | Según la transición: `users.status.deactivate` / `.reactivate` / `.block` / `.unblock`, + dominancia |
| Request | `{"estado": "activo"\|"bloqueado"\|"inactivo", "motivo": str}` |
| 200 | `UserOut` |
| Errores | 403 `forbidden` / `self_management_forbidden` · 404 · 409 `invalid_status_transition` / `last_admin` · 422 |
| Auditoría | `users.status.changed` con `{"estado": antes}` → `{"estado": después, "motivo": ...}` |

Reactivar a una cuenta sin contraseña la deja en `pendiente` (B §2.2). Después hay que
enviarle una invitación.

### 2.6 `POST /users/{usuario_id}/roles` · `DELETE /users/{usuario_id}/roles/{rol}`

| | POST | DELETE |
|---|---|---|
| Permiso | `roles.assign.<rol>` + dominancia sobre los roles **actuales** del destino | ídem |
| Request | `{"rol": "MENTOR"}` | — (`{rol}` = código) |
| Respuesta | `201 UserOut` si se asignó; `200 UserOut` si ya lo tenía | `204` |
| Errores | 403 `forbidden` / `self_management_forbidden` · 404 (usuario o rol) · 422 | 403 · 404 (no lo tenía) · 409 `last_admin` / `last_role` |
| Auditoría | `users.role.assigned` | `users.role.revoked` |

### 2.7 `GET /users/{usuario_id}/permissions`

Permiso `users.read.all` y además `permissions.read` →
`200 {"usuario_id": 42, "permisos": [{"nombre": "...", "via_roles": ["MENTOR"]}]}`.
Sirve para la pantalla "Consulta de permisos" (J §11).

---

## 3. Roles y permisos (`modules/users`)

| Método y ruta | Permiso | 200 |
|---|---|---|
| `GET /roles` | `roles.read` | `[RoleOut]` (sin paginar: son 4) |
| `GET /roles/{rol}` | `roles.read` | `RoleOut` con `permisos` ordenados |
| `GET /permissions` | `permissions.read` | `[PermissionOut]` con `"roles": ["COORDINADOR", ...]` |

**No** hay `POST`, `PATCH` ni `DELETE` de roles o permisos (C-D §2, punto 4; N-14).

## 4. Auditoría (`modules/audit`)

### `GET /audit/events`

| | |
|---|---|
| Permiso | `audit.read` |
| Query | `page`, `page_size`, `usuario_id`, `accion` (prefijo, p. ej. `auth.`), `tabla`, `id_registro`, `desde`, `hasta` (ISO-8601; rango ≤ 366 días) |
| 200 | `Page[{"bitacora_id", "usuario_id", "accion", "tabla", "id_registro", "datos_anteriores", "datos_nuevos", "ip", "fecha"}]`, ordenado por `fecha` descendente |

## 5. Dependencias FastAPI por endpoint (resumen)

```python
@router.get("", response_model=Page[UserOut])
async def list_users(
    principal: CurrentPrincipal,
    _: None = require_permissions(Permission.USERS_READ_ALL),
    params: UserListParams = Depends(),
    service: UserService = Depends(get_user_service),
) -> Page[UserOut]:
    return await service.list_users(params)
```

Las reglas de dominancia, "no a uno mismo" y último administrador se aplican en
`service.py` y en `policies.py`, no en el router.
