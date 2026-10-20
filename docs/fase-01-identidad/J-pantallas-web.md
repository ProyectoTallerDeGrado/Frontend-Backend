# J — Diseño funcional de pantallas web

## 0. Reglas comunes [P]

- **Idioma** de la interfaz: español. Rutas e identificadores: inglés (regla global §4.9).
- **Componentes:** primitivas de shadcn `base-rhea` sobre `@base-ui/react`
  (`components/ui/`), compuestas en `features/<f>/components/`. Iconos de `lucide-react`.
  Colores **solo** con los tokens de `app/globals.css` (regla 10 de la web).
- **Formularios:** `<form action={serverAction}>` + `useActionState`. La validación con
  zod se hace **en el servidor** (en la Server Action) y se replica en el cliente solo
  como ayuda: el resultado del servidor manda. Los errores de campo van bajo cada
  input (`aria-describedby`) y el error general en un `Alert` al inicio del formulario.
- **Botón de envío:** se deshabilita mientras `isPending`, con un spinner y el texto
  "Guardando…". Así se evita el doble envío.
- **Estados estándar** de cada pantalla con datos: `loading.tsx` con `Skeleton`, vacío
  (ilustración + texto + acción principal), error (`error.tsx` con "Reintentar"),
  `404` (`not-found.tsx`) y `403` (§5).
- **Permisos en la UI:** se usa `PermissionGate` (oculta) o un botón deshabilitado con
  un `Tooltip` que explica por qué. Es **solo cosmética**: el backend decide.
- **Breakpoints de Tailwind:** `sm` 640, `md` 768, `lg` 1024. Por debajo de `md`, la
  barra lateral pasa a ser un `Sheet` con un botón de menú; las tablas pasan a ser
  listas de tarjetas; los diálogos ocupan toda la pantalla.
- **Accesibilidad:** foco visible; `label` en cada campo; orden de tabulación lógico;
  contraste AA; `aria-live="polite"` en los mensajes de resultado; los mensajes de
  error de autenticación no revelan qué campo falló.
- **Mapeo de errores de la API a la UI** (`lib/api-client.ts` → `ApiError`):

  | Código | Comportamiento en la UI |
  |---|---|
  | `validation_error`, `weak_password` | Errores por campo. |
  | `email_taken` | Error en el campo `email`. |
  | `forbidden` | Una notificación (*toast*) "No tienes permiso para esta acción". |
  | `not_found` | La página 404. |
  | `session_revoked`, `invalid_refresh_token` | Se borran las cookies y se va a `/session-expired`. |
  | `too_many_attempts` | Un mensaje con la cuenta atrás de `Retry-After`. |
  | `last_admin`, `last_role`, `invalid_status_transition`, `self_management_forbidden` | Un `Alert` con el `message` del backend. |

### Shell autenticado (`(app)/layout.tsx`)

```
┌────────────────────────────────────────────────────────────────────┐
│ ☰  EmprendeU                                   [🔔]  Ana Quispe ▾   │  ← header (UserMenu: Perfil, Cerrar sesión)
├───────────────┬────────────────────────────────────────────────────┤
│ Inicio        │  PageHeader: título + migas + acción principal     │
│ Emprendim.    │                                                    │
│ ───────────   │  contenido                                         │
│ Administración│                                                    │
│  Usuarios     │                                                    │
│  Roles        │                                                    │
│  Permisos     │                                                    │
└───────────────┴────────────────────────────────────────────────────┘
```

La barra lateral muestra cada entrada **solo** si el usuario tiene alguno de los
permisos de esa sección (p. ej., "Usuarios" ⇐ `users.read.all`).

---

## 1. Inicio de sesión — `/login`

| Aspecto | Especificación |
|---|---|
| Layout | `(public)`: una tarjeta centrada de máximo 400 px, con el logo encima y el pie institucional. |
| Componentes | `Card`, `Label`, `Input`, `Button`, `Alert`; enlace a "¿Olvidaste tu contraseña?". |
| Campos | `email` (`type=email`, `autocomplete=username`, `inputmode=email`, autofocus); `password` (`type=password`, `autocomplete=current-password`, con un botón 👁 para mostrarla). |
| Validaciones | Los dos son obligatorios; formato de correo; la contraseña hasta 128 caracteres (sin validar la política aquí). |
| Acciones | "Iniciar sesión" → Server Action `login` → `POST /auth/login {client:"web"}` → cookies → `redirect(next \|\| '/')`. `next` se valida con `safeNextPath`. |
| Estados | Inicial; enviando; error `invalid_credentials` ("Correo o contraseña incorrectos."; se vacía la contraseña y el foco vuelve a ella); `account_disabled` ("Tu cuenta está deshabilitada. Contacta al CIE-U."); `too_many_attempts` ("Demasiados intentos. Inténtalo en N min.", con el botón deshabilitado hasta entonces); `?reason=expired` → `Alert` informativo "Tu sesión expiró". |
| Permisos | Pública. Con una sesión válida, `redirect('/')`. |
| API | `POST /auth/login`. |
| Responsive | Por debajo de `sm`, la tarjeta ocupa el ancho completo con 16 px de margen. |

```
        ┌───────────────────────────────┐
        │          [ EmprendeU ]          │
        │  Inicia sesión                  │
        │  Correo institucional           │
        │  [ ana@universidad.edu      ]   │
        │  Contraseña                     │
        │  [ ••••••••••••          👁 ]   │
        │  [      Iniciar sesión      ]   │
        │  ¿Olvidaste tu contraseña?      │
        └───────────────────────────────┘
```

## 2. Recuperar la contraseña — `/forgot-password`

| Aspecto | Especificación |
|---|---|
| Layout | `(public)`, una tarjeta. |
| Campos | `email`. |
| Validaciones | Obligatorio; formato. |
| Acciones | "Enviar instrucciones" → `POST /auth/password/forgot`. |
| Estados | Tras enviar: **siempre** el mismo mensaje, "Si el correo está registrado, recibirás un enlace válido por 30 minutos. Revisa también tu carpeta de spam." El formulario se oculta y aparece un enlace "Volver al inicio de sesión". El mensaje es idéntico, salga bien o mal, para no revelar si la cuenta existe. |
| Permisos | Pública. |
| Responsive | Como en `/login`. |

## 3. Restablecer la contraseña — `/reset-password#token=…` y activar la cuenta — `/activate#token=…`

| Aspecto | Especificación |
|---|---|
| Layout | `(public)`, una tarjeta. Cabeceras `Referrer-Policy: no-referrer` y `Cache-Control: no-store`. |
| Componentes | `SetPasswordForm` (componente **cliente**: lee `location.hash`, guarda el token en estado de React y hace `history.replaceState` para quitarlo de la URL), `PasswordStrengthHints`. |
| Campos | `new_password` (`autocomplete=new-password`) y `confirm_password`. |
| Validaciones | Cliente: coinciden; longitud de 12 a 128; una lista de requisitos que se marcan a medida que se escribe (longitud, no contiene el correo). Servidor: la política completa (`weak_password` con `reasons` → mensajes). |
| Acciones | Reset: Server Action `resetPassword` → `POST /auth/password/reset`. Activación: `acceptInvitation` → `POST /auth/invitations/accept`. Si sale bien → `/login?reason=password_set`, con el mensaje "Contraseña establecida. Inicia sesión." |
| Estados | Sin token en el *fragment* → "Enlace inválido" + "Solicitar uno nuevo". `invalid_or_expired_token` → "El enlace caducó o ya se usó", con un enlace a `/forgot-password` (en la activación: "Pide al CIE-U que te reenvíe la invitación"). |
| Permisos | Pública. Si hay una sesión iniciada, se muestra un aviso: "Se cerrará tu sesión actual". |
| Responsive | Como en `/login`. |

## 4. Sesión expirada — `/session-expired`

| Aspecto | Especificación |
|---|---|
| Layout | `(public)`, una tarjeta con un icono `Clock`. |
| Contenido | "Tu sesión terminó" + el motivo genérico ("por inactividad, porque cerraste sesión en otro dispositivo o por seguridad"). No se distingue la causa. |
| Acciones | "Iniciar sesión de nuevo" → `/login?next=<next validado>`. |
| Estados | Uno solo. Al cargar, se borran las cookies si quedara alguna (Server Action en `useEffect`, o el propio `proxy.ts`). |
| Permisos | Pública. |

## 5. Acceso denegado — 403

| Aspecto | Especificación |
|---|---|
| Ruta | Opción A (recomendada si se aprueba N-16): `app/(app)/forbidden.tsx` + `forbidden()` con `experimental.authInterrupts`. **Conserva la URL** y responde con el estado 403. Opción B: `/forbidden` + `redirect()`. |
| Layout | Dentro del shell `(app)`, con la navegación visible. |
| Contenido | Icono `ShieldX`, "No tienes acceso a esta sección", "Si crees que es un error, contacta al administrador del CIE-U." |
| Acciones | "Volver al inicio". |
| Disparo | `requirePermission(code)` en la página del servidor cuando `getSession().permisos` no contiene el código, o cuando el backend responde `403 forbidden`. Un `404` del backend (fuera de alcance) **no** muestra esta página, sino la de "No encontrado". |

## 6. Perfil — `/profile`

| Aspecto | Especificación |
|---|---|
| Layout | Shell `(app)`, `Tabs`: **Datos**, **Seguridad**, **Sesiones**. Una columna centrada de máximo 720 px. |
| Datos | Lectura: nombre, apellido, correo, roles (`Badge`), estado y fecha de registro. Edición: solo `telefono` (formulario en línea, Server Action → `PATCH /auth/me`). Nota: "Para cambiar tu nombre o correo, contacta al CIE-U" (N-27). |
| Seguridad | `ChangePasswordForm`: `current_password`, `new_password`, `confirm`. Si sale bien: un *toast* "Contraseña actualizada. Cerramos tus otras sesiones." Errores: `invalid_current_password` en el campo; `weak_password`. |
| Sesiones | `SessionsList` (`GET /auth/sessions`): dispositivo o navegador (a partir del `agente_usuario`, con un formato simple), IP, último uso, "Esta sesión" (`Badge`). Acciones: "Cerrar" en cada fila (con un `AlertDialog`; → `DELETE /auth/sessions/{sid}`) y "Cerrar todas las sesiones" (un `AlertDialog` que avisa de que también se cerrará esta → `POST /auth/logout-all` → `/login`). |
| Permisos | Cualquier sesión activa (permiso implícito). |
| Estados | Cargando (esqueleto), error por pestaña y lista vacía (imposible, porque siempre está la actual). |
| Responsive | Las pestañas pasan a ser un `Select` por debajo de `sm`; las sesiones se muestran como tarjetas. |

## 7. Gestión de usuarios — `/admin/users`

| Aspecto | Especificación |
|---|---|
| Layout | Shell `(app)`. `PageHeader` con el título "Usuarios" y el botón "Nuevo usuario" (solo con `users.create`). |
| Componentes | `UsersFilters` (búsqueda con *debounce* de 300 ms, `Select` de estado, `Select` de rol), `UsersTable` (`Table`), `Pagination`. |
| Columnas | Nombre completo (enlace al detalle), correo, roles (`Badge`), estado (`Badge`: activo = éxito, pendiente = aviso, bloqueado = destructivo, inactivo = neutro), fecha de registro, y acciones (`DropdownMenu`: Ver, Editar, Cambiar estado, Roles, Reenviar invitación). Las acciones se filtran por los permisos efectivos. |
| Estado de la URL | Los filtros y la página van en los `searchParams` (`?q=&estado=&rol=&page=`), **no** en Zustand: así se pueden compartir y la página se renderiza en el servidor. |
| Validaciones | `q` con 2 caracteres como mínimo (con menos, no se filtra). |
| API | `GET /users` en el Server Component (`features/users/server/queries.ts`). |
| Estados | Cargando (filas esqueleto); vacío con filtros ("Ningún usuario coincide" + "Limpiar filtros"); vacío sin filtros ("Aún no hay usuarios" + "Nuevo usuario"); error. |
| Permisos | La página exige `users.read.all` (si no, la 403 del §5). |
| Responsive | Por debajo de `md`, cada usuario es una tarjeta (nombre, correo, *badges* y un menú ⋯); los filtros se agrupan en un `Sheet` "Filtros". |

```
Usuarios                                              [ + Nuevo usuario ]
[ 🔍 Buscar por nombre o correo ] [ Estado ▾ ] [ Rol ▾ ]
┌──────────────────┬─────────────────────────┬──────────────┬───────────┬────────────┬───┐
│ Nombre           │ Correo                  │ Roles        │ Estado    │ Registro   │   │
├──────────────────┼─────────────────────────┼──────────────┼───────────┼────────────┼───┤
│ Carla Mamani     │ carla.mamani@univ...    │ EMPRENDEDOR  │ pendiente │ 20/10/2026 │ ⋯ │
│ Luis Rojas       │ luis@univ...            │ MENTOR       │ activo    │ 01/09/2026 │ ⋯ │
└──────────────────┴─────────────────────────┴──────────────┴───────────┴────────────┴───┘
                                                       ‹ 1 2 3 ›   57 usuarios
```

## 8. Detalle de usuario — `/admin/users/[userId]`

| Aspecto | Especificación |
|---|---|
| Layout | `PageHeader` con el nombre, el *badge* de estado y las acciones (Editar, Cambiar estado, Gestionar roles, Reenviar invitación / Enviar restablecimiento, Cerrar sesiones). Debajo, una `Card` "Datos" + una `Card` "Roles" + una `Card` "Sesiones activas" (solo con `users.sessions.read`) + un enlace "Ver permisos efectivos". |
| Acciones | **Cambiar estado** → `UserStatusDialog` (§9.2). **Reenviar invitación** (si está `pendiente`) → `POST /auth/users/{id}/invitation` → *toast* "Invitación enviada". **Enviar restablecimiento** (si está `activo`) → `POST /auth/users/{id}/password-reset`. **Cerrar sesiones** → un `AlertDialog` con `motivo` → `POST /auth/users/{id}/sessions/revoke`. |
| Estados | 404 si no existe **o** si el backend lo oculta. Si el actor es el mismo usuario: se ocultan "Cambiar estado" y "Roles", con el aviso "Para tu propia cuenta usa Perfil". |
| Permisos | `users.read.all`; cada acción, según C §3.1. Una acción rechazada por dominancia (`403`) muestra "No puedes gestionar a usuarios con el rol X". |
| API | `GET /users/{id}`, `GET /auth/users/{id}/sessions`. |
| Responsive | Las tarjetas se apilan; las acciones se agrupan en un `DropdownMenu` "Acciones" por debajo de `md`. |

## 9. Formulario de alta y edición — `/admin/users/new` · `/admin/users/[userId]/edit`

### 9.1 Formulario (`UserForm`)

| Campo | Control | Validación (cliente y servidor) | Alta | Edición |
|---|---|---|---|---|
| Nombre | `Input` | Obligatorio, de 1 a 160 caracteres. | ✔ | ✔ |
| Apellido | `Input` | Obligatorio, de 1 a 120 caracteres. | ✔ | ✔ |
| Correo | `Input type=email` | Obligatorio, formato, ≤ 254; `email_taken` desde el servidor. | ✔ | ✔ (con el aviso: "Cambiar el correo cerrará todas las sesiones del usuario") |
| Teléfono | `Input type=tel` | Opcional, `^[+0-9 ()-]{6,35}$`. | ✔ | ✔ |
| Roles | Un `Checkbox` por rol | Al menos 1. **Solo** se muestran los roles que el actor puede asignar (los `roles.assign.*` de su `getSession()`); el resto, deshabilitado con un *tooltip*. | ✔ | — (se gestionan en §10) |

- **Alta:** "Crear y enviar invitación" → Server Action `createUser` = `POST /users` +
  `POST /auth/users/{id}/invitation`.
  - Si todo va bien → al detalle, con el *toast* "Usuario creado. Se envió la invitación a <correo>."
  - Si la invitación falla → al detalle, con un `Alert` de aviso y el botón "Reintentar envío".
- **Edición:** "Guardar cambios" → `PATCH /users/{id}` con **solo** los campos que
  cambiaron. "Cancelar" vuelve al detalle. Si hay cambios sin guardar, se pide
  confirmación antes de salir.
- **Permisos:** alta = `users.create`; edición = `users.update` (y dominancia en el servidor).
- **Responsive:** una columna; dos columnas para nombre y apellido a partir de `md`.

### 9.2 Diálogo de cambio de estado (`UserStatusDialog`)

- `RadioGroup` solo con las transiciones válidas desde el estado actual **y** permitidas
  al actor (B §2.2, C §3.1). `motivo` en un `Textarea` (obligatorio, de 3 a 500 caracteres).
- El texto de consecuencias cambia según la opción. Bloquear o desactivar: "Se cerrarán
  todas sus sesiones de inmediato." Reactivar sin contraseña: "Quedará pendiente y
  deberás reenviarle la invitación."
- `last_admin` → "No puedes dejar el sistema sin administradores activos."

## 10. Asignación de roles — `/admin/users/[userId]/roles`

| Aspecto | Especificación |
|---|---|
| Layout | Una lista de los 4 roles como filas `Card`: nombre, descripción, "N permisos" (desplegable con la lista, de `GET /roles/{rol}`) y un `Switch` asignado/no asignado. |
| Interacción | Cambiar un `Switch` abre un `AlertDialog` de confirmación ("¿Asignar MENTOR a Luis Rojas?"), que llama a `POST /users/{id}/roles` o a `DELETE /users/{id}/roles/{rol}`. Hay actualización optimista con *rollback* si la llamada falla. |
| Reglas en la UI | `Switch` deshabilitado si falta `roles.assign.<rol>`, si es uno mismo, o si es el último rol (con un *tooltip*). Si se intenta asignar `EMPRENDEDOR` y el usuario no tiene perfil, aparece el aviso "Recuerda crear su perfil de emprendedor", con un enlace (cuando exista la fase de `entrepreneurs`). |
| Errores | `last_admin`, `last_role` y `forbidden` → `Alert` + *rollback*. |
| Permisos | Alguno de los `roles.assign.*`. |
| Responsive | Las filas se apilan; el `Switch` queda alineado a la derecha. |

## 11. Consulta de permisos — `/admin/roles` · `/admin/permissions` · permisos efectivos

| Vista | Ruta | Permiso | Contenido |
|---|---|---|---|
| Catálogo de roles | `/admin/roles` | `roles.read` | Una `Card` por rol con su descripción y una **matriz** de permisos agrupados por dominio (en `Tabs` por dominio en móvil). Solo lectura, con el aviso "Los permisos se modifican mediante una migración revisada". |
| Catálogo de permisos | `/admin/permissions` | `permissions.read` | Una tabla con el código (`font-mono`), la descripción, el alcance (un *badge*: `all`/`assigned`/`own`/`self`/institucional) y los roles que lo tienen. Filtros: dominio y rol; búsqueda por código. |
| Permisos efectivos de un usuario | `/admin/users/[userId]` → la sección "Ver permisos efectivos" (un `Sheet` lateral) | `users.read.all` + `permissions.read` | La lista de `GET /users/{id}/permissions`, con la columna "Vía" (los roles que lo conceden). |

- **Estados:** cargando, error. Vacío no aplica: los catálogos siempre tienen datos tras la siembra.
- **Responsive:** las matrices pasan a ser listas por dominio con acordeón por debajo de `md`.
