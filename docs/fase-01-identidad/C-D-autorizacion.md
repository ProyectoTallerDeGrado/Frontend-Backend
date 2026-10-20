# C — Matriz RBAC · D — Políticas de autorización

## 1. Convenciones de permisos [P]

- **Código estable:** `<dominio>.<accion>[.<alcance>]`, en minúsculas, separado por puntos
  y `≤ 160` caracteres (cabe en `permiso.nombre`). Una vez publicado **no se renombra**;
  si cambia su semántica se crea uno nuevo y el viejo se retira por migración.
- **Alcances:**

  | Sufijo | Significa | Cómo se resuelve |
  |---|---|---|
  | `.all` | Acceso **institucional** a todas las instancias. | Sin filtro de pertenencia. |
  | `.assigned` | Solo los emprendimientos con una **asignación vigente** del actor. | Resolver `assigned` (§7.1), del módulo `mentoring`. |
  | `.own` | Solo los emprendimientos de los que el actor es **miembro vigente** como emprendedor. | Resolver `own` (§7.2), del módulo `entrepreneurs`. |
  | `.self` | Solo filas que describen al propio actor (sus asignaciones, su inscripción). | `usuarioid = principal.usuario_id`. |
  | *(sin sufijo)* | Permiso institucional no ligado a un emprendimiento (catálogos, administración). | — |

- **Recurso** y **acción** se derivan del código: el recurso es el primer segmento
  (y el segundo si es un subrecurso) y la acción es el verbo. Por eso no hacen falta
  columnas nuevas en `permiso`.
- **[P] Migración incremental:** `permiso.descripcion TEXT NULL`, para mostrarla en la
  pantalla de consulta de permisos (J §11). Es opcional: si no se aprueba, la
  descripción vive solo en este documento.
- **Roles:** A = `ADMINISTRADOR`, C = `COORDINADOR`, M = `MENTOR`, E = `EMPRENDEDOR`.
- **Columna "Siembra":** `✔` = se concede en la migración inicial;
  `○` = el permiso **existe** pero **no se concede** a nadie hasta que el CIE-U decida (N-xx).
- **Riesgo:** C = crítico (escalada de privilegios o toma de cuentas),
  A = alto (datos personales o empresariales sensibles, acciones irreversibles),
  M = medio, B = bajo.
- **Endpoint:** los de `auth`, `users`, `roles`, `permissions` y `audit` se definen en
  [G](G-contratos-api.md). Los demás son **rutas previstas** para la fase de cada
  módulo y aquí solo fijan qué permiso exigirán.

## 2. Única fuente de verdad [P]

1. Las asignaciones rol→permiso viven **solo** en `rol_permiso`.
2. Las siembra una **migración de datos** de Alembic (`seed_roles_permisos`), con
   `INSERT ... ON CONFLICT (nombre) DO NOTHING` para `rol` y `permiso` y `ON CONFLICT
   ON CONSTRAINT uq_rol_permiso_rolid_permisoid DO NOTHING` para `rol_permiso`. Su
   `downgrade` borra solo las filas sembradas y falla si algún rol sembrado está
   asignado a usuarios.
3. El código contiene **solo los códigos** que comprueba, en `modules/users/permissions.py`
   (`StrEnum Permission`), nunca qué rol los tiene. Un test compara el enum con
   las filas de `permiso` tras `alembic upgrade head`: todo código del enum existe en la BD,
   y viceversa.
4. Cambiar la matriz = **nueva migración** revisada en un PR. **No existe API para
   editar `rol_permiso`** en esta fase: queda fuera de alcance para no abrir una vía
   de escalada en caliente (N-14).
5. Las decisiones `[D]` del CIE-U se aplican con una migración que inserta o borra
   filas de `rol_permiso`, sin tocar código.

## 3. Catálogo completo de permisos

### 3.1 `users` — administración de cuentas

| Código | Recurso / acción | Descripción | Roles (siembra) | Condiciones adicionales | Endpoint | Riesgo |
|---|---|---|---|---|---|---|
| `users.read.all` | users / read | Listar y ver cualquier cuenta (datos de perfil, estado, roles). | A ✔ · C ✔ | Nunca se devuelve `password_hash`. | `GET /users`, `GET /users/{id}` | A |
| `users.create` | users / create | Crear una cuenta `pendiente`. | A ✔ · C ✔ | Exige además `roles.assign.<r>` para **cada** rol inicial. | `POST /users` | C |
| `users.update` | users / update | Editar nombre, apellido, teléfono y correo de otra cuenta. | A ✔ · C ✔ | Dominancia (B §7.1.2). Si cambia el correo, se revocan sus sesiones y se avisa al correo antiguo. | `PATCH /users/{id}` | C |
| `users.status.deactivate` | users / status | `activo`/`bloqueado`/`pendiente` → `inactivo`. | A ✔ · C ✔ | Dominancia, no a uno mismo, último administrador. | `POST /users/{id}/status` | A |
| `users.status.reactivate` | users / status | `inactivo` → `activo` o `pendiente`. | A ✔ · C ✔ | Dominancia. | `POST /users/{id}/status` | A |
| `users.status.block` | users / status | `activo` → `bloqueado` (seguridad). | A ✔ | Dominancia, no a uno mismo, último administrador. Se exige `motivo`. | `POST /users/{id}/status` | A |
| `users.status.unblock` | users / status | `bloqueado` → `activo`. | A ✔ | Dominancia. | `POST /users/{id}/status` | A |
| `users.credentials.reset` | users / credentials | Enviar a otra cuenta el enlace de restablecimiento o de invitación. | A ✔ · C ✔ | Dominancia. **Nunca** devuelve el token al actor (N-10). | `POST /auth/users/{id}/password-reset`, `POST /auth/users/{id}/invitation` | C |
| `users.sessions.read` | users / sessions | Ver las sesiones activas de otra cuenta. | A ✔ | Dominancia. | `GET /auth/users/{id}/sessions` | M |
| `users.sessions.revoke` | users / sessions | Cerrar todas las sesiones de otra cuenta. | A ✔ | Dominancia. | `POST /auth/users/{id}/sessions/revoke` | M |

**Implícitos** (basta con estar autenticado y `activo`, sin fila en `permiso`): ver el propio perfil
(`GET /auth/me`), editar el propio teléfono (`PATCH /auth/me`), cambiar la propia contraseña,
y listar y cerrar las propias sesiones. Se documentan como implícitos para no tener que sembrar un
permiso que todos los roles deben tener y que, si se quitara por error, dejaría a la
gente sin poder cerrar su sesión.

### 3.2 `roles` y `permissions`

| Código | Recurso / acción | Descripción | Roles (siembra) | Condiciones | Endpoint | Riesgo |
|---|---|---|---|---|---|---|
| `roles.read` | roles / read | Ver el catálogo de roles y sus permisos. | A ✔ · C ✔ | — | `GET /roles`, `GET /roles/{code}` | B |
| `roles.assign.administrador` | roles / assign | Asignar o revocar `ADMINISTRADOR`. | A ✔ | Dominancia, no a uno mismo, último administrador. | `POST /users/{id}/roles`, `DELETE /users/{id}/roles/{code}` | C |
| `roles.assign.coordinador` | roles / assign | Asignar o revocar `COORDINADOR`. | A ✔ | Dominancia, no a uno mismo. | ídem | C |
| `roles.assign.mentor` | roles / assign | Asignar o revocar `MENTOR`. | A ✔ · C ○ (N-05) | Dominancia, no a uno mismo. | ídem | A |
| `roles.assign.emprendedor` | roles / assign | Asignar o revocar `EMPRENDEDOR`. | A ✔ · C ✔ | Dominancia, no a uno mismo. | ídem | A |
| `permissions.read` | permissions / read | Ver el catálogo de permisos. | A ✔ | — | `GET /permissions` | B |

### 3.3 `audit`

| Código | Descripción | Roles | Condiciones | Endpoint | Riesgo |
|---|---|---|---|---|---|
| `audit.read` | Consultar `bitacora`. | A ✔ | Solo eventos de identidad y seguridad mientras los módulos de negocio no definan qué auditan (§6). | `GET /audit/events` | A |

### 3.4 `entrepreneurs`

| Código | Descripción | Roles | Condiciones | Endpoint previsto | Riesgo |
|---|---|---|---|---|---|
| `entrepreneurs.read.all` | Ver cualquier perfil de emprendedor. | C ✔ | — | `GET /entrepreneurs`, `GET /entrepreneurs/{id}` | A |
| `entrepreneurs.read.assigned` | Ver a los emprendedores miembros de emprendimientos asignados. | M ✔ | Sin `documento_identidad`. | ídem (filtrado) | A |
| `entrepreneurs.read.own` | Ver el propio perfil. | E ✔ | Incluye el propio `documento_identidad`. | `GET /entrepreneurs/me` | M |
| `entrepreneurs.identity.read.all` | Ver `documento_identidad` de cualquier emprendedor. | C ✔ | Control a nivel de campo. | ídem | A |
| `entrepreneurs.create` | Crear el perfil `emprendedor` (y la cuenta, en la misma transacción). | C ✔ | La cuenta destino debe tener el rol `EMPRENDEDOR`. | `POST /entrepreneurs` | A |
| `entrepreneurs.update.all` | Editar el perfil y su estado. | C ✔ | — | `PATCH /entrepreneurs/{id}` | A |

### 3.5 `ventures`

| Código | Descripción | Roles | Condiciones | Endpoint previsto | Riesgo |
|---|---|---|---|---|---|
| `ventures.read.all` | Ver cualquier emprendimiento. | C ✔ (§5) | — | `GET /ventures`, `GET /ventures/{id}` | A |
| `ventures.read.assigned` | Ver emprendimientos con asignación vigente. | M ✔ · C ○ (§5) | §7.1 | ídem (filtrado) | A |
| `ventures.read.own` | Ver los emprendimientos propios. | E ✔ | §7.2 | ídem (filtrado) | A |
| `ventures.create` | Crear un emprendimiento. | C ✔ · E ○ (N-13) | — | `POST /ventures` | M |
| `ventures.update.all` | Editar datos generales de cualquier emprendimiento. | C ✔ | — | `PATCH /ventures/{id}` | A |
| `ventures.update.own` | Editar `descripcion` y `sector` del propio emprendimiento. | E ○ (N-13) | Lista blanca de campos | `PATCH /ventures/{id}` | M |
| `ventures.status.update` | Cambiar `emprendimiento.estado` (cerrar, archivar). | C ✔ | Se exige `motivo`. | `POST /ventures/{id}/status` | A |
| `ventures.members.manage` | Altas y bajas en `emprendimiento_emprendedores`. | C ✔ | **Concede el alcance `own`**: crítico. | `POST/DELETE /ventures/{id}/members` | C |
| `ventures.stages.manage.all` | Avanzar o retroceder etapas de cualquier emprendimiento. | C ✔ | Una sola etapa activa (`uq_emprendimiento_etapa_activa`). | `POST /ventures/{id}/stages` | A |
| `ventures.stages.manage.assigned` | Ídem, en los asignados. | M ○ (N-13) | — | ídem | A |
| `ventures.progress.write.all` | Registrar hitos y necesidades. | C ✔ | — | `POST /ventures/{id}/milestones`, `/needs` | M |
| `ventures.progress.write.assigned` | Ídem, en los asignados. | M ✔ | — | ídem | M |
| `ventures.progress.write.own` | Ídem, en los propios. | E ○ (N-13) | — | ídem | M |
| `ventures.catalog.manage` | Mantener los catálogos `etapas` y `necesidades`. | C ✔ | — | `/ventures/catalog/*` | M |

### 3.6 `mentoring`

| Código | Descripción | Roles | Condiciones | Endpoint previsto | Riesgo |
|---|---|---|---|---|---|
| `mentoring.assignments.read.all` | Ver todas las asignaciones. | C ✔ | — | `GET /mentoring/assignments` | M |
| `mentoring.assignments.read.self` | Ver mis asignaciones. | M ✔ | `usuarioid = actor` | `GET /mentoring/assignments?mine=true` | B |
| `mentoring.assignments.manage` | Crear, terminar o suspender asignaciones. | C ✔ | **Concede el alcance `assigned`**: crítico. El destinatario debe tener el rol `MENTOR` o `COORDINADOR` y estar `activo`; se aplica la regla de conflicto de interés (N-09). | `POST/PATCH /mentoring/assignments` | C |
| `mentoring.sessions.read.all` | Ver sesiones de acompañamiento, participantes y recomendaciones. | C ✔ | — | `GET /ventures/{id}/mentoring-sessions` | A |
| `mentoring.sessions.read.assigned` | Ídem, en los asignados. | M ✔ | — | ídem | A |
| `mentoring.sessions.read.own` | Ídem, en los propios. | E ✔ | `observaciones` internas del mentor: N-18. | ídem | A |
| `mentoring.sessions.manage.all` | Programar o editar sesiones. | C ✔ | — | `POST/PATCH ...` | M |
| `mentoring.sessions.manage.assigned` | Ídem, en los asignados. | M ✔ | — | ídem | M |
| `mentoring.recommendations.write.all` | Emitir recomendaciones. | C ✔ | — | `POST /ventures/{id}/recommendations` | M |
| `mentoring.recommendations.write.assigned` | Ídem, en los asignados. | M ✔ | — | ídem | M |

### 3.7 `followup` — `seguimientos` y `compromisos` (módulo `mentoring`)

| Código | Descripción | Roles | Condiciones | Endpoint previsto | Riesgo |
|---|---|---|---|---|---|
| `followup.read.all` | Ver seguimientos y compromisos. | C ✔ | — | `GET /ventures/{id}/followups` | A |
| `followup.read.assigned` | Ídem, en los asignados. | M ✔ | — | ídem | A |
| `followup.read.own` | Ídem, en los propios. | E ✔ | — | ídem | M |
| `followup.write.all` | Registrar seguimientos y compromisos. | C ✔ | — | `POST/PATCH ...` | M |
| `followup.write.assigned` | Ídem, en los asignados. | M ✔ | — | ídem | M |
| `followup.commitments.complete.own` | Marcar como cumplido un compromiso propio. | E ○ (N-13) | `compromisos.usuarioid = actor` | `POST /followups/commitments/{id}/complete` | B |

### 3.8 `gamification`

| Código | Descripción | Roles | Condiciones | Endpoint previsto | Riesgo |
|---|---|---|---|---|---|
| `gamification.read.all` | Ver XP, insignias y retos de cualquier emprendedor o emprendimiento. | C ✔ | — | `GET /gamification/...` | B |
| `gamification.read.assigned` | Ídem, en los asignados. | M ✔ | — | ídem | B |
| `gamification.read.own` | Ver lo propio. | E ✔ | — | `GET /gamification/me` | B |
| `gamification.catalog.manage` | Mantener `insignias` y `retos`. | C ✔ | — | `/gamification/catalog/*` | M |
| `gamification.challenges.assign.all` | Asignar retos a emprendimientos. | C ✔ | — | `POST /ventures/{id}/challenges` | M |
| `gamification.challenges.assign.assigned` | Ídem, en los asignados. | M ○ (N-13) | — | ídem | M |
| `gamification.xp.grant` | Movimiento manual de XP. | C ✔ | Se exige `motivo`; auditado; `cantidad` acotada (N-19). | `POST /gamification/xp-movements` | A |

### 3.9 `alerts`

| Código | Descripción | Roles | Condiciones | Endpoint previsto | Riesgo |
|---|---|---|---|---|---|
| `alerts.read.all` | Ver alertas. | C ✔ | — | `GET /alerts` | A |
| `alerts.read.assigned` | Ídem, de los asignados. | M ✔ | — | ídem | A |
| `alerts.read.own` | Ver las alertas del propio emprendimiento. | E ○ (N-20) | — | ídem | M |
| `alerts.manage.all` | Atender o cerrar alertas. | C ✔ | — | `PATCH /alerts/{id}` | M |
| `alerts.manage.assigned` | Ídem, de los asignados. | M ✔ | — | ídem | M |
| `alerts.catalog.manage` | Mantener `tipos` (`TipoAlerta`). | C ✔ | — | `/alerts/catalog/*` | B |

### 3.10 `reports` — módulo `indicators` y consultas agregadas

| Código | Descripción | Roles | Condiciones | Endpoint previsto | Riesgo |
|---|---|---|---|---|---|
| `reports.read.institutional` | Reportes agregados de todo el programa. | C ✔ | Agregados; sin datos personales por fila. | `GET /reports/...` | A |
| `reports.read.assigned` | Indicadores de los asignados. | M ✔ | — | `GET /ventures/{id}/indicators` | M |
| `reports.read.own` | Indicadores propios. | E ✔ | — | ídem | B |
| `reports.export` | Exportar reportes (CSV/XLSX). | C ✔ | Auditado con filtros y número de filas; exfiltración masiva. | `GET /reports/.../export` | A |
| `reports.indicators.write.all` | Registrar `valores_indicadores`. | C ✔ | — | `POST /ventures/{id}/indicators` | M |
| `reports.indicators.write.assigned` | Ídem, en los asignados. | M ✔ | — | ídem | M |
| `reports.indicators.write.own` | Ídem, en los propios. | E ○ (N-13) | — | ídem | M |
| `reports.catalog.manage` | Mantener `tipos_indicadores`. | C ✔ | — | `/reports/catalog/*` | B |

### 3.11 `ai` — módulo `ai_assistant`

| Código | Descripción | Roles | Condiciones | Endpoint previsto | Riesgo |
|---|---|---|---|---|---|
| `ai.chat.use.own` | Conversar con el asistente sobre los propios emprendimientos. | E ✔ | `conversaciones_ia.emprendedorid` = el perfil del actor; `emprendimientoid` ∈ `own`. | `POST /ai/conversations`, `/messages` | M |
| `ai.conversations.read.own` | Ver las propias conversaciones. | E ✔ | — | `GET /ai/conversations` | M |
| `ai.conversations.read.assigned` | Ver las conversaciones de los emprendedores asignados. | M ○ (N-21) | Datos muy sensibles. | ídem | A |
| `ai.sentiment.read.all` | Ver `analisis_sentimiento`. | C ○ (N-21) | Perfilado de personas. | `GET /ai/sentiment` | A |
| `ai.sentiment.read.assigned` | Ídem, de los asignados. | M ○ (N-21) | — | ídem | A |
| `ai.knowledge.manage` | Mantener `documentos_conocimiento` y `fragmentos_documento`. | C ✔ · A ○ (N-04) | — | `/ai/knowledge/*` | M |

### 3.12 `documents`

| Código | Descripción | Roles | Condiciones | Endpoint previsto | Riesgo |
|---|---|---|---|---|---|
| `documents.read.all` | Ver o descargar cualquier documento. | C ✔ | Descargas firmadas y de corta vida (fase `documents`). | `GET /documents/{id}` | A |
| `documents.read.assigned` | Ídem, de los asignados. | M ✔ | `documentos.emprendimientoid` ∈ `assigned`. Un documento sin emprendimiento solo es visible para su autor y para `.all`. | ídem | A |
| `documents.read.own` | Ídem, de los propios. | E ✔ | ídem con `own`. | ídem | A |
| `documents.upload.all` | Subir documentos. | C ✔ | — | `POST /ventures/{id}/documents` | M |
| `documents.upload.assigned` | Ídem, a los asignados. | M ✔ | — | ídem | M |
| `documents.upload.own` | Ídem, a los propios. | E ✔ | — | ídem | M |
| `documents.delete.all` | Eliminar cualquier documento. | C ✔ | — | `DELETE /documents/{id}` | A |
| `documents.delete.own` | Eliminar documentos que yo subí. | E ✔ · M ✔ | `documentos.usuarioid = actor` **y** alcance de lectura vigente. | ídem | M |

### 3.13 `training` — no estaba en la lista del prompt, pero el módulo existe [C]

| Código | Descripción | Roles | Endpoint previsto | Riesgo |
|---|---|---|---|---|
| `training.read` | Ver el catálogo de capacitaciones. | C ✔ · M ✔ · E ✔ | `GET /training` | B |
| `training.manage` | Crear y editar capacitaciones y registrar la asistencia. | C ✔ | `POST/PATCH /training` | M |
| `training.enroll.self` | Inscribirse en una capacitación. | E ○ (N-13) | `POST /training/{id}/enrollments` | B |

## 4. Matriz resumen por rol (siembra por defecto)

`all` = institucional, `asg` = asignados, `own` = propios, `—` = sin acceso, `○` = pendiente CIE-U.

| Dominio | ADMINISTRADOR | COORDINADOR | MENTOR | EMPRENDEDOR |
|---|---|---|---|---|
| users | gestión total | gestión de emprendedores (dominancia) | — | yo (implícito) |
| roles | asignar los 4 | asignar `EMPRENDEDOR` (+ `MENTOR` ○) | — | — |
| permissions / audit | lectura | roles: lectura | — | — |
| sesiones ajenas | ver y revocar | — | — | — |
| entrepreneurs | — | all | asg (sin documento) | own |
| ventures | — | all (§5) | asg | own (lectura; edición ○) |
| mentoring | — | all + gestión de asignaciones | asg | own (lectura) |
| followup | — | all | asg | own (lectura) |
| gamification | — | all + catálogo + XP | asg | own |
| alerts | — | all | asg | ○ |
| reports | — | institucional + exportación | asg | own |
| ai | ○ conocimiento | conocimiento (sentimiento ○) | ○ | chat propio |
| documents | — | all | asg | own |
| training | — | gestión | lectura | lectura (inscripción ○) |

---

# D — Políticas de autorización por emprendimiento

## 5. Alcance del coordinador: política configurable [P] / [D]

El alcance del coordinador **se configura con datos, no con código**: depende de qué
variante del permiso tenga el rol `COORDINADOR` en `rol_permiso`.

| Política | Permisos del rol `COORDINADOR` | Efecto |
|---|---|---|
| **`institucional`** (por defecto propuesto) | `*.read.all`, `*.write.all`, `*.manage.all`... | Ve y gestiona todos los emprendimientos del CIE-U. |
| **`por_asignacion`** | `*.read.assigned`, `*.write.assigned`... y **mantiene** `mentoring.assignments.manage` | Solo los emprendimientos donde tiene una fila vigente en `asignaciones` con `tipo_asignacion = 'coordinacion'`. Aun así puede crearse asignaciones a sí mismo: requiere N-22 (¿quién asigna coordinadores?). |

- Cambiar de política = una migración que intercambia filas de `rol_permiso`. No
  hace falta ningún *flag* de entorno: si hubiera uno, habría una segunda fuente de
  verdad.
- La decisión es del CIE-U (**N-04**). Hasta entonces se siembra `institucional`.

## 6. Separación del administrador [P] / [D]

- `ADMINISTRADOR` = **administración técnica**: cuentas, roles, sesiones, auditoría y
  catálogo de permisos.
- **No** recibe ningún permiso `.all`, `.assigned` ni `.own` de dominios de negocio
  (`entrepreneurs`, `ventures`, `mentoring`, `followup`, `alerts`, `reports`, `ai`,
  `documents`). Un `GET /ventures/{id}` de un administrador puro devuelve **403**.
- Si una persona necesita las dos facetas, se le asignan **dos roles**
  (`ADMINISTRADOR` + `COORDINADOR`). La asignación es explícita y queda auditada.
- `users.read.all` expone datos personales (nombre, correo, teléfono) pero no datos
  empresariales. `audit.read` puede contener `datos_anteriores/nuevos`. Por eso
  los módulos de negocio, cuando auditen, **no** deben volcar campos sensibles en
  `bitacora` (se aplica en sus fases).
- Confirmación institucional: **N-04**.

## 7. Resolución de alcance

### 7.1 Vigencia de una asignación (resolver `assigned`) [P]

Una fila de `asignaciones` concede alcance al usuario `u` sobre el emprendimiento `v` si se cumple **todo** esto:

```sql
SELECT a.emprendimientoid
FROM cieu.asignaciones a
WHERE a.usuarioid = :u
  AND (:v IS NULL OR a.emprendimientoid = :v)
  AND lower(btrim(a.estado)) = 'activa'
  AND a.fecha_inicio IS NOT NULL
  AND a.fecha_inicio <= now()
  AND (a.fecha_fin IS NULL OR a.fecha_fin > now())
```

| Regla | Decisión |
|---|---|
| Vocabulario de `asignaciones.estado` | `activa`, `suspendida`, `finalizada`. Solo `activa` concede acceso. El CHECK se añadirá en la fase de `mentoring`, no en esta. |
| `fecha_inicio` NULL | **No vigente** (falla cerrado). El servicio que crea asignaciones siempre la fija. |
| `fecha_fin` NULL | Vigente indefinidamente mientras siga `activa`. |
| `fecha_fin` | **Exclusiva**: a partir de ese instante ya no hay acceso. Es `TIMESTAMPTZ`; la UI que pida "hasta el día D" guarda `D+1 00:00` en la zona horaria institucional (N-23). |
| Varias filas para el mismo par | Basta con que **una** sea vigente. |
| `tipo_asignacion` | No interviene en la autorización (vocabulario `mentoria`/`coordinacion`, N-22). La política se expresa con los permisos del rol, no con el tipo. |
| Usuario de la asignación | La cuenta debe estar `activo` (ya garantizado por el `Principal`). |
| Rol de la persona asignada | No se vuelve a comprobar aquí: el permiso `*.assigned` solo lo tiene quien tiene un rol con ese permiso. Si se le revoca `MENTOR`, pierde el permiso aunque la asignación siga viva. |

Reloj: `now()` de PostgreSQL, en la transacción del request, para no depender del
reloj del servidor de aplicaciones.

### 7.2 Membresía vigente (resolver `own`) [P]

```sql
SELECT ee.emprendimientoid
FROM cieu.emprendedor ep
JOIN cieu.emprendimiento_emprendedores ee ON ee.emprendedorid = ep.emprendedorid
WHERE ep.usuarioid = :u
  AND (:v IS NULL OR ee.emprendimientoid = :v)
  AND lower(btrim(ep.estado)) = 'activo'
  AND ee.fecha_ingreso IS NOT NULL
  AND ee.fecha_ingreso <= now()
  AND (ee.fecha_salida IS NULL OR ee.fecha_salida > now())   -- requiere la migración E-H §1.3
```

- `fecha_ingreso` NULL → **no vigente**, por coherencia con 7.1.
- Mientras no exista `fecha_salida` (N-17), la baja de un miembro es un `DELETE` de la
  fila, auditado con la fila completa en `datos_anteriores`.
- `rol_en_emprendimiento` (texto libre) **no** concede permisos distintos.

### 7.3 Estado del emprendimiento [P] / [D]

El estado de `emprendimiento` **no** forma parte de la comprobación de lectura: un
emprendimiento cerrado sigue siendo legible por quien tiene alcance. Las
**escrituras** sobre emprendimientos cerrados o archivados se rechazarán en las
fases de negocio (`409 venture_closed`). El vocabulario de estados es N-24.

## 8. Algoritmo de decisión [P]

Para la acción base `b` (p. ej., `ventures.read`) sobre el emprendimiento `v`:

```
decidir(principal, b, v):
  1. principal es activo                      → si no: 401 (ya lo resuelve la autenticación)
  2. alcances = { s ∈ {all, assigned, own} : f"{b}.{s}" ∈ principal.permisos }
  3. si alcances = ∅                          → 403 forbidden
  4. si "all" ∈ alcances                      → permitido si v existe; si no, 404
  5. accesibles = ⋃ resolver_s(principal.usuario_id, v) para s ∈ alcances − {all}
  6. si v ∈ accesibles                        → permitido
  7. si no                                    → 404 not_found  (aunque v exista)
```

- **Listados:** se construye `WHERE emprendimientoid IN (<subconsulta de cada resolver>)`
  en el repositorio. No se aplica un filtro en memoria ni se pagina antes de filtrar,
  para que `total` no cuente filas inaccesibles.
- **Recursos hijos** (sesión de mentoría, documento, alerta...): se carga el
  `emprendimientoid` del hijo **en la misma consulta** que lo filtra por alcance. Si
  no aparece → 404. Así no hay una ventana TOCTOU entre "comprobar" y "leer".
- Las **escrituras** usan la acción base de escritura (`ventures.progress.write`) con el
  mismo algoritmo; la lectura nunca implica escritura.
- **Recursos del propio actor** (`.self`): `WHERE usuarioid = principal.usuario_id`.

## 9. Reglas de denegación y no filtración [P]

| Situación | Respuesta |
|---|---|
| Sin token, token inválido o caducado | `401` + `WWW-Authenticate: Bearer error="invalid_token"` |
| Sesión revocada o cuenta no activa | `401 session_revoked` (se cierra la sesión en el cliente) |
| Autenticado, sin **ninguna** variante del permiso | `403 forbidden` (la ruta en sí es pública: no revela nada) |
| Con permiso de alcance, recurso fuera de alcance | `404 not_found` (idéntico al de un id inexistente: mismo `message` y mismo cuerpo) |
| Id malformado (no entero o fuera del rango de 64 bits) | `422 validation_error` (antes de consultar la BD) |
| Acción sobre uno mismo prohibida | `403 self_management_forbidden` |
| Dominancia no satisfecha sobre un usuario | `404 not_found` si el actor **no** tiene `users.read.all`; `403 forbidden` si lo tiene (ya puede ver que el usuario existe) |
| Existencia por tiempos | Los 404 por alcance y por inexistencia ejecutan la misma consulta filtrada: no hay una consulta previa "¿existe?". |
| Enumeración de correos | Login, forgot-password e invitación devuelven respuestas indistinguibles para correos inexistentes (G). |

## 10. Registros inactivos [P]

| Registro | Efecto en la autorización |
|---|---|
| `usuario.estado ≠ activo` | Ningún permiso. Todo request protegido → 401. |
| `rol_usuario` de una cuenta inactiva | Se conserva, pero es inerte. |
| `emprendedor.estado ≠ activo` | Pierde el alcance `own`; mantiene los permisos sin alcance (p. ej., `training.read`). |
| Asignación `suspendida`/`finalizada` o fuera de fechas | Pierde el alcance `assigned` de ese emprendimiento. |
| Membresía con `fecha_salida` pasada | Pierde el alcance `own` de ese emprendimiento. |
| Sesión revocada o caducada | 401. No se reactiva nunca: se inicia una sesión nueva. |
| Permiso retirado de un rol | Efecto en el siguiente request (sin caché). |

## 11. Interfaz de `core/authz.py` (contrato, sin implementación)

```python
@dataclass(frozen=True, slots=True)
class Principal:
    usuario_id: int
    session_id: UUID          # claim sid
    client_type: ClientType   # "web" | "mobile"
    permissions: frozenset[str]
    roles: frozenset[str]     # solo para mostrar; NUNCA para decidir

class VentureScopeResolver(Protocol):
    async def __call__(self, db: AsyncSession, usuario_id: int, venture_id: int | None) -> Select[tuple[int]]: ...
    # Devuelve una subconsulta de emprendimientoid, componible en el WHERE de un repositorio.

class PrincipalResolver(Protocol):
    async def __call__(self, db: AsyncSession, token: str, ctx: ClientContext) -> Principal: ...

def configure_authorization(app: FastAPI, *, principal_resolver: PrincipalResolver,
                            scopes: Mapping[Scope, VentureScopeResolver]) -> None: ...

CurrentPrincipal = Annotated[Principal, Depends(get_principal)]

def require_permissions(*codes: str, mode: Literal["all", "any"] = "all") -> Depends: ...
def require_scope(action: str) -> Depends:   # inyecta un VentureFilter con los alcances del principal
    ...
class VentureFilter:
    scopes: frozenset[Scope]
    def as_subquery(self) -> Select[tuple[int]] | None: ...   # None => alcance "all"
    async def ensure(self, venture_id: int) -> None: ...       # 404 si no está en alcance
```

`core/authz.py` **no importa nada de `modules/`**. `api/v1.py` llama a
`configure_authorization` en `create_app()` con `auth.resolve_principal`,
`mentoring.assigned_venture_ids` y `entrepreneurs.member_venture_ids`, todos de las
API públicas (`__init__.py`) de sus módulos.
