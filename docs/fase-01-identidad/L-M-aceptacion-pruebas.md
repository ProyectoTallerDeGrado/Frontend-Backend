# L — Criterios de aceptación · M — Matriz de pruebas

## 1. Criterios de aceptación de la implementación

Una fase de implementación de identidad solo se da por terminada si **todos** los
criterios aplicables se cumplen y se demuestran con la salida real de los comandos.

### 1.1 Funcionales

- **L-F01** Existen y responden según [G](G-contratos-api.md) todos los endpoints de
  G §1–§4, con los códigos HTTP y de error documentados.
- **L-F02** `create-admin` crea el primer administrador y se niega a crear un segundo
  sin `--break-glass`.
- **L-F03** Un administrador puede crear cuentas de los 4 roles; un coordinador, solo
  `EMPRENDEDOR` (siembra por defecto).
- **L-F04** El ciclo invitación → activación → login → refresh → logout funciona de
  punta a punta en la web y en el móvil.
- **L-F05** Las transiciones de estado de B §2.2 son las únicas aceptadas.
- **L-F06** Asignar o revocar un rol cambia los permisos efectivos en el **siguiente
  request**, sin volver a iniciar sesión.
- **L-F07** Los flujos I-17…I-20 se comportan según C-D §7–§9 (con un endpoint de
  prueba si las fases de negocio aún no existen; N-28).

### 1.2 Seguridad

- **L-S01** Las contraseñas se guardan solo como Argon2id (formato PHC `$argon2id$`). No
  hay contraseñas por defecto, ni en los datos sembrados ni en `.env.example`.
- **L-S02** El JWT se valida de forma estricta (E-H §4.3): todo caso de T-SES-12 da 401.
- **L-S03** Un access token **no caducado** de una sesión revocada se rechaza con
  `401 session_revoked` (T-SES-14).
- **L-S04** Reutilizar un refresh rotado, pasada la gracia, revoca la familia (T-SES-02).
- **L-S05** El navegador no tiene acceso a los tokens: cookies `__Host-` `HttpOnly`
  `Secure` `SameSite=Lax`; nada en `localStorage`, `sessionStorage`, Zustand, el HTML ni
  el *payload* RSC (T-WEB-01…03).
- **L-S06** El móvil guarda el refresh solo en `flutter_secure_storage` y el access solo
  en memoria (T-MOB-01).
- **L-S07** Ningún endpoint público crea cuentas ni asigna roles (T-USR-12).
- **L-S08** No hay forma de autoasignarse roles, de gestionarse el propio estado ni de
  dejar el sistema sin administradores (T-ADM-04, -05, -16, -18).
- **L-S09** No se pueden enumerar cuentas por login, forgot-password, el límite de
  intentos ni el 404 de alcance (T-AUTH-02/03/08, T-PWD-08, T-AZ-15/27).
- **L-S10** Los logs y la `bitacora` no contienen contraseñas, tokens ni hashes (T-SEC-01).
- **L-S11** La app no arranca en producción sin las claves JWT y HMAC válidas (T-SEC-02).
- **L-S12** No hay ninguna prueba desactivada, `skip` sin justificación, ni control de
  seguridad apagado "para pasar".

### 1.3 Integración y arquitectura

- **L-I01** `core/` no importa nada de `modules/` (comprobación estática: `grep` o un
  test de imports).
- **L-I02** Los imports entre módulos van solo por el `__init__.py`; `users` no importa `auth`.
- **L-I03** La migración baseline no ha cambiado (`git diff` vacío sobre
  `cfed9e8e2430_*.py`); `alembic upgrade head` funciona sobre una base virgen;
  `alembic check` no detecta operaciones; `downgrade -1` funciona en cada migración
  nueva.
- **L-I04** El enum `Permission` y la tabla `permiso` coinciden (T-AZ-07).
- **L-I05** Los esquemas de OpenAPI coinciden con los tipos zod de la web y los DTO de
  Flutter de los mismos endpoints (revisión en el mismo PR, regla global §5).
- **L-I06** Los `AGENTS.md` de las tres apps están actualizados según las marcas **AG** de K.
- **L-I07** No se añaden dependencias al backend. En la web, solo `zod` (y Playwright o
  Vitest si se aprueba N-29b).

### 1.4 Calidad

- **L-Q01** `uv run ruff check src/ && uv run ruff format --check src/`: sin errores.
- **L-Q02** `uv run pytest`: todo en verde contra PostgreSQL real; se reporta la salida.
- **L-Q03** `pnpm lint` y `pnpm build`: sin errores.
- **L-Q04** `flutter analyze` y `flutter test`: sin errores.

## 2. Matriz de pruebas

Nivel: **U** = unitaria (sin BD), **R** = repositorio o servicio contra PostgreSQL,
**A** = API (`httpx.AsyncClient` + app + PostgreSQL), **E** = extremo a extremo
(navegador o dispositivo), **S** = estática (imports, OpenAPI, código fuente).

### 2.1 Aprovisionamiento — T-BOOT

| ID | Caso | Esperado | Nivel |
|---|---|---|---|
| T-BOOT-01 | `create-admin` sin administradores | Usuario `activo` + rol + auditoría; código 0 | R |
| T-BOOT-02 | Segunda ejecución | Código 2, sin cambios | R |
| T-BOOT-03 | Contraseña débil | Código 3, nada persistido | R |
| T-BOOT-04 | Correo repetido con distinta capitalización | Código 4 | R |
| T-BOOT-05 | Sin la siembra de roles | Código 5 | R |
| T-BOOT-06 | La contraseña no aparece en stdout, stderr ni logs; no existe un argumento `--password` | Captura limpia | U |

### 2.2 Altas — T-USR

| ID | Caso | Esperado | Nivel |
|---|---|---|---|
| T-USR-01 | El administrador crea un `COORDINADOR` | 201, `pendiente`, `password_hash` NULL, rol, auditoría | A |
| T-USR-02 | El administrador crea un `MENTOR` | 201 | A |
| T-USR-03 | El coordinador crea un `COORDINADOR` | 403; nada persistido | A |
| T-USR-04 | El coordinador crea un `MENTOR` (siembra por defecto) | 403 | A |
| T-USR-05 | Correo existente con otra capitalización | 409 `email_taken` | A |
| T-USR-06 | `roles: []`; un campo extra `estado` en el body | 422 (las dos) | A |
| T-USR-07 | Invitación emitida | Solo el hash en la BD; el correo (`MemoryMailSender`) contiene `#token=`; la respuesta no tiene el token | A |
| T-USR-08 | El mentor llama a `POST /users` | 403 | A |
| T-USR-09 | El coordinador crea un `EMPRENDEDOR` | 201 | A |
| T-USR-10 | Segundo perfil `emprendedor` para el mismo usuario | 409 (fase de `entrepreneurs`) | A |
| T-USR-11 | Login de una cuenta `pendiente` | 401 con el cuerpo idéntico al de un correo inexistente | A |
| T-USR-12 | No hay ningún endpoint público que cree usuarios ni roles | Revisión de las rutas de OpenAPI y sus dependencias | S |

### 2.3 Login — T-AUTH

| ID | Caso | Esperado | Nivel |
|---|---|---|---|
| T-AUTH-01 | Credenciales válidas | 200; fila de sesión; `token_refresco.hash_token` = SHA-256 del token devuelto; auditoría | A |
| T-AUTH-02 | Contraseña incorrecta | 401 `invalid_credentials` | A |
| T-AUTH-03 | Correo inexistente | Cuerpo idéntico a T-AUTH-02; se invoca `dummy_verify` (espía) | A |
| T-AUTH-04 | `"  ANA@Univ.EDU "` | 200 | A |
| T-AUTH-05 | Cuenta `inactivo`: con la contraseña correcta y con una incorrecta | 403 `account_disabled` / 401 | A |
| T-AUTH-06 | Cuenta `bloqueado`: ídem | 403 / 401 | A |
| T-AUTH-07 | Cuenta `activo` con el hash NULL | 401 + auditoría `auth.login.null_password` | A |
| T-AUTH-08 | 5 fallos y después la contraseña correcta; ídem con un correo inexistente | 429 + `Retry-After` en los dos casos | A |
| T-AUTH-09 | 20 fallos desde una IP con correos distintos; `X-Forwarded-For` desde un *peer* no confiable | 429; se ignora la cabecera | A |
| T-AUTH-10 | Hash con parámetros antiguos | El login lo rehace (`verify_and_update`) | R |
| T-AUTH-11 | Contraseña de 129 caracteres o de más de 1024 bytes | 422 sin calcular el hash (espía) | A |
| T-AUTH-12 | Ni la respuesta ni los logs contienen la contraseña | Captura de `structlog` | A |

### 2.4 Sesiones, tokens y JWT — T-SES

| ID | Caso | Esperado | Nivel |
|---|---|---|---|
| T-SES-01 | Refresh válido | Par nuevo; el viejo con `fecha_uso`; mismo `sid`; `jti` nuevo | A |
| T-SES-02 | Reutilizar el token viejo pasada la gracia (reloj +11 s) | 401; sesión revocada `reutilizacion_detectada`; el sucesor también falla; auditoría | A |
| T-SES-03 | Reutilizar dentro de la gracia | 409 `refresh_superseded`; la sesión sigue | A |
| T-SES-04 | Dos refresh concurrentes del mismo token (`asyncio.gather`) | Uno 200 y otro 409; nunca dos tokens vigentes (`uq_token_refresco_vigente`) | R |
| T-SES-05 | Refresh caducado por inactividad | 401 | A |
| T-SES-06 | Sesión con la caducidad absoluta vencida y el refresh aún "vivo" | 401 | A |
| T-SES-07 | Token inventado | 401; ninguna sesión revocada | A |
| T-SES-08 | Token web presentado con `client: "mobile"` | 401 | A |
| T-SES-09 | Refresh de un usuario desactivado | 401; sesión `cuenta_deshabilitada` | A |
| T-SES-10 | `refresh_token` de más de 100 caracteres | 422 | A |
| T-SES-11 | `GET /auth/me` | 200 `MeOut`, sin hash | A |
| T-SES-12 | JWT manipulado, parametrizado: `alg: none`; `alg: HS512`; `kid` desconocido; firma con otra clave; `iss` o `aud` distintos; sin `sid`, `jti`, `nbf` o `exp`; `token_type: "refresh"`; `exp-iat` > TTL; `nbf` futuro; `sub` no numérico; más de 4096 bytes | 401 `invalid_token` en cada caso | A |
| T-SES-13 | Access caducado | 401 `token_expired` + `WWW-Authenticate` | A |
| T-SES-14 | **Access vigente de una sesión revocada** | 401 `session_revoked` | A |
| T-SES-15 | Logout | 204; refresh → 401; access del mismo `sid` → 401 | A |
| T-SES-16 | Logout con un token basura | 204 | A |
| T-SES-17 | Logout repetido | 204 | A |
| T-SES-18 | `logout-all` con 3 sesiones | Las 3 revocadas; el access de otra sesión → 401 | A |
| T-SES-19 | `DELETE /auth/sessions/{sid}` de otro usuario | 404 | A |

### 2.5 Contraseñas — T-PWD

| ID | Caso | Esperado | Nivel |
|---|---|---|---|
| T-PWD-01 | Cambio correcto | 204; las demás sesiones revocadas; la actual vive; auditoría; aviso por correo | A |
| T-PWD-02 | Contraseña actual incorrecta | 400 `invalid_current_password`; las sesiones intactas | A |
| T-PWD-03 | Nueva débil, parametrizado: corta, común, contiene el correo o el nombre, igual a la actual | 422 `weak_password` con `reasons` | U + A |
| T-PWD-04 | 5 fallos de la actual | 429 | A |
| T-PWD-05 | La anterior ya no sirve y la nueva sí | — | A |
| T-PWD-06 | Los restablecimientos pendientes quedan invalidados tras el cambio | — | R |
| T-PWD-07 | `forgot` de una cuenta activa | 202 + correo; solo el hash en la BD | A |
| T-PWD-08 | `forgot` de un correo inexistente | 202 con el cuerpo idéntico; sin correo | A |
| T-PWD-09 | `forgot` de una cuenta `inactivo`, `bloqueado` o `pendiente` | 202; sin correo de restablecimiento | A |
| T-PWD-10 | Aceptar una invitación válida | 204; `activo`; hash Argon2id; token usado | A |
| T-PWD-11 | Aceptar con un token ya usado | 400 `invalid_or_expired_token` | A |
| T-PWD-12 | Aceptar con un token caducado (reloj +73 h) | 400 | A |
| T-PWD-13 | Aceptar cuando la cuenta ya no está `pendiente` | 400 | A |
| T-PWD-14 | Una invitación nueva invalida la anterior | La anterior → 400 | A |
| T-PWD-15 | Restablecimiento válido | 204; **todas** las sesiones revocadas; login con la nueva | A |
| T-PWD-16 | Restablecimiento reutilizado | 400 | A |
| T-PWD-17 | Restablecimiento caducado (reloj +31 min) | 400 | A |
| T-PWD-18 | Token de invitación usado en `/password/reset` | 400 | A |
| T-PWD-19 | Cuarta solicitud de `forgot` en una hora | 202; sin correo | A |
| T-PWD-20 | Los tokens no aparecen en logs, en la auditoría ni en las respuestas | Captura | A |

### 2.6 Administración — T-ADM

| ID | Caso | Esperado | Nivel |
|---|---|---|---|
| T-ADM-01 | El administrador desactiva a un coordinador | 200; el siguiente request del coordinador → 401 | A |
| T-ADM-02 | El coordinador desactiva a un emprendedor | 200 | A |
| T-ADM-03 | El coordinador desactiva a un mentor | 403 (dominancia) | A |
| T-ADM-04 | Desactivarse a uno mismo | 403 `self_management_forbidden` | A |
| T-ADM-05 | El último administrador; dos administradores se desactivan mutuamente en paralelo | 409 `last_admin`; queda ≥ 1 administrador activo | R |
| T-ADM-06 | `pendiente → bloqueado` | 409 `invalid_status_transition` | A |
| T-ADM-07 | Sin `motivo` | 422 | A |
| T-ADM-08 | Bloqueado: login con la contraseña correcta; tokens de cuenta pendientes | 403; los tokens → 400 | A |
| T-ADM-09 | Desbloquear | `activo`; las sesiones viejas siguen revocadas | A |
| T-ADM-10 | Reactivar con y sin contraseña | `activo` / `pendiente` | A |
| T-ADM-11 | El coordinador intenta desbloquear | 403 | A |
| T-ADM-12 | Auditoría de los cambios de estado | Antes y después correctos; sin campos sensibles | A |
| T-ADM-13 | Asignar `MENTOR` | 201; el **mismo** access del destino gana los permisos en su siguiente request | A |
| T-ADM-14 | Asignar un rol que ya tiene | 200; sin auditoría duplicada | A |
| T-ADM-15 | El coordinador asigna `MENTOR` / `EMPRENDEDOR` | 403 / 201 | A |
| T-ADM-16 | Asignarse un rol a uno mismo | 403 | A |
| T-ADM-17 | Revocar un rol | 204; el siguiente request del destino → 403 en el recurso | A |
| T-ADM-18 | Revocar el último `ADMINISTRADOR` | 409 `last_admin` | A |
| T-ADM-19 | Revocar el último rol | 409 `last_role` | A |
| T-ADM-20 | Invitación a una cuenta `pendiente` / `activo` | 202 / 409 | A |
| T-ADM-21 | `password-reset` del administrador | 202; sin token en la respuesta | A |
| T-ADM-22 | El coordinador envía un restablecimiento a un mentor | 403 | A |
| T-ADM-23 | Listar las sesiones de otro usuario | 200; sin hashes | A |
| T-ADM-24 | Revocar las sesiones de otro usuario | 204; su access → 401; `revocada_por` en la sesión; auditoría | A |
| T-ADM-25 | `PATCH` del correo | Sesiones revocadas; aviso al correo anterior; correo duplicado → 409 | A |
| T-ADM-26 | `PATCH` con `estado` o `roles` | 422 | A |

### 2.7 Autorización — T-AZ

| ID | Caso | Esperado | Nivel |
|---|---|---|---|
| T-AZ-01 | Sin `Authorization` | 401 `not_authenticated` + `WWW-Authenticate` | A |
| T-AZ-02 | Esquema `Basic` | 401 | A |
| T-AZ-03 | El mentor llama a `GET /users` | 403 | A |
| T-AZ-04 | El administrador llama a `GET /users`; `page_size=101` | 200 con la forma `Page`; 422 | A |
| T-AZ-05 | Se borra en la BD una fila de `rol_permiso` | El siguiente request → 403 (sin caché) | A |
| T-AZ-06 | Los claims del JWT no contienen roles, permisos, correo ni nombre | — | U |
| T-AZ-07 | El enum `Permission` coincide con la tabla `permiso` | — | R |
| T-AZ-08 | Formato de error en 401, 403, 404, 409, 422 y 429; los `details` del 422 sin `input` | — | A |
| T-AZ-10 | Mentor con una asignación vigente → la ruta de prueba | 200 | A |
| T-AZ-11 | Estado `' Activa '` | 200 | A |
| T-AZ-12 | `fecha_fin` NULL | 200 | A |
| T-AZ-13 | Varias filas, una vigente | 200 | A |
| T-AZ-14 | Listado del mentor | Solo los asignados; `total` exacto | A |
| T-AZ-15 | Sin asignación | 404 **byte a byte igual** al de un id inexistente | A |
| T-AZ-16 | Asignación `finalizada` | 404 | A |
| T-AZ-17 | Asignación `suspendida` | 404 | A |
| T-AZ-18 | `fecha_inicio` futura | 404 | A |
| T-AZ-19 | `fecha_inicio` NULL | 404 | A |
| T-AZ-20 | `fecha_fin` pasada y `fecha_fin = now()` (exclusiva) | 404 | A |
| T-AZ-21 | La asignación es de otro mentor | 404 | A |
| T-AZ-22 | Le revocaron `MENTOR` pero la asignación sigue activa | 403 | A |
| T-AZ-23 | Emprendedor en su emprendimiento | 200 | A |
| T-AZ-24 | Listado del emprendedor | Solo los suyos | A |
| T-AZ-25 | Miembro de dos emprendimientos | Ve los dos | A |
| T-AZ-26 | `fecha_ingreso` futura | 404 | A |
| T-AZ-27 | Emprendimiento ajeno | 404 igual al de uno inexistente | A |
| T-AZ-28 | `emprendedor.estado = inactivo` | 404 | A |
| T-AZ-29 | `fecha_ingreso` NULL | 404 | A |
| T-AZ-30 | Con los roles `EMPRENDEDOR` + `MENTOR` | Ve la unión exacta | A |
| T-AZ-31 | Coordinador (institucional) | Cualquiera → 200; uno inexistente → 404 | A |
| T-AZ-32 | Administrador puro | 403 (separación, C-D §6) | A |

### 2.8 Transversales — T-SEC / T-MIG

| ID | Caso | Esperado | Nivel |
|---|---|---|---|
| T-SEC-01 | Se recorren todos los flujos con captura de logs y de `bitacora` | Ninguna aparición de las contraseñas usadas, de `eurt_`, `euat_`, `eyJ` ni `$argon2` | A |
| T-SEC-02 | `ENVIRONMENT=production` sin `JWT_SIGNING_KEYS`, con una clave de menos de 32 bytes o un `kid` activo inexistente | La app no arranca (`ValidationError`) | U |
| T-SEC-03 | `.env.example` | Sin valores para los secretos | S |
| T-SEC-04 | Todas las rutas de `/users`, `/roles`, `/permissions`, `/audit` y `/auth/users` dependen de `get_principal` | — | S |
| T-SEC-05 | Ninguna respuesta lleva `Access-Control-Allow-Origin` | — | A |
| T-SEC-06 | `Cache-Control: no-store` en `/auth/*` y en las respuestas autenticadas | — | A |
| T-SEC-07 | El hashing de Argon2 se ejecuta fuera del event loop | Espía de `to_thread` | U |
| T-SEC-08 | `core/` no importa `modules/`; `users` no importa `auth` | — | S |
| T-MIG-01 | `alembic upgrade head` sobre una base virgen; `alembic check`; `downgrade -1` por cada revisión nueva; `pg_dump` comparado con lo esperado | Correcto | R |
| T-MIG-02 | La siembra ejecutada dos veces | Sin duplicados | R |
| T-MIG-03 | La baseline no cambió | `git diff` vacío | S |

### 2.9 Web — T-WEB (necesita un *runner*: N-29b)

| ID | Caso | Esperado | Nivel |
|---|---|---|---|
| T-WEB-01 | `Set-Cookie` del login | `__Host-`, `HttpOnly`, `Secure`, `SameSite=Lax`, `Path=/` | E |
| T-WEB-02 | El HTML, el *payload* RSC y el JS servido no contienen `eyJ` ni `eurt_` | — | E |
| T-WEB-03 | `localStorage` y `sessionStorage` vacíos tras el login | — | E |
| T-WEB-04 | Server Action invocada con otro `Origin` | Rechazada | E |
| T-WEB-05 | Access caducado al navegar | Renovación transparente; cookies rotadas | E |
| T-WEB-06 | Dos pestañas renuevan a la vez | Las dos continúan (ruta del 409) | E |
| T-WEB-07 | Sesión revocada desde otro dispositivo | Redirige a `/session-expired` | E |
| T-WEB-08 | `safeNextPath('//evil.com')`, `'https://evil'`, `'/\\evil'` | `'/'` | U |
| T-WEB-09 | Un `route.ts` con un método que muta y no llama a `assertSameOrigin` | El test falla | S |
| T-WEB-10 | Un mentor no ve "Administración"; la URL directa → 403 | — | E |
| T-WEB-11 | `/reset-password` quita el *fragment* y responde con `Referrer-Policy: no-referrer` | — | E |

### 2.10 Móvil — T-MOB (`flutter test` + `mocktail`, ya en `dev_dependencies` [C])

| ID | Caso | Esperado |
|---|---|---|
| T-MOB-01 | Tras el login: el refresh solo en el *mock* de secure storage; el access nunca persistido | — |
| T-MOB-02 | 3 peticiones concurrentes reciben 401 | 1 sola llamada a `/auth/refresh` |
| T-MOB-03 | Reintento único: un segundo 401 | Estado `unauthenticated` |
| T-MOB-04 | `session_revoked` | Storage vacío; redirige a `/login` |
| T-MOB-05 | Error de red en el refresh | Los tokens se conservan; estado `offline` |
| T-MOB-06 | Logout sin red | Storage vacío igualmente |
| T-MOB-07 | Orden: se escribe el refresh nuevo antes de usar el access | Verificado con `verifyInOrder` |
| T-MOB-08 | El `LogInterceptor` oculta `Authorization` | — |
