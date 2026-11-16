# Backend EmprendeU — Arquitectura modular

> Lee antes `../../AGENTS.md` (reglas globales del monorepo).
> Este documento es **prescriptivo**: define cómo debe quedar el backend.

---

## 1. Stack

| Pieza | Elección | Estado |
|---|---|---|
| Lenguaje | Python **3.13** (`.python-version`) | instalado |
| Gestor / build | **uv** (`uv_build` como build-backend) | instalado |
| Framework HTTP | **FastAPI** `>=0.142.2` | en uso (`emprendeu.main:create_app`) |
| Servidor ASGI | **uvicorn[standard]** `>=0.54.0` | instalado |
| ORM | **SQLAlchemy 2.x async** | en uso: 43 modelos declarativos |
| Driver | **psycopg 3** (`postgresql+psycopg://`) | instalado |
| Migraciones | **Alembic** (plantilla `async`) | en uso, con migración base |
| Layout | `src/` layout, paquete `emprendeu` | instalado |

### Dependencias acordadas

| Librería | Función | Prioridad | Grupo |
|---|---|---|---|
| `fastapi` | API REST, validación y documentación | Esencial | ejecución |
| `uvicorn[standard]` | Servidor ASGI | Esencial | ejecución |
| `sqlalchemy[asyncio]` | ORM, consultas y relaciones PostgreSQL con soporte async | Esencial | ejecución |
| `psycopg[binary]` | Driver PostgreSQL 3 con soporte asíncrono | Esencial | ejecución |
| `alembic` | Migraciones y versionado de la BD | Esencial | ejecución |
| `pydantic` | Esquemas de entrada y salida | Esencial | ejecución |
| `pydantic-settings` | Configuración y variables de entorno | Esencial | ejecución |
| `PyJWT` | Verificación y creación de JWT | Autenticación | ejecución |
| `pwdlib[argon2]` | Hash de contraseñas para login local | Autenticación | ejecución |
| `httpx` | Solicitudes HTTP asíncronas e integración externa | Recomendado | ejecución |
| `pytest` | Pruebas automatizadas | Esencial | desarrollo |
| `pytest-asyncio` | Pruebas de operaciones asíncronas | Recomendado | desarrollo |
| `ruff` | Linter y formateador | Recomendado | desarrollo |
| `structlog` | Logs estructurados | Recomendado | ejecución |
| `pgvector` | Tipo `vector` de SQLAlchemy (embeddings del asistente) | Recomendado | ejecución |

Estado actual: **todas** están declaradas en `pyproject.toml`, resueltas en
`uv.lock` e instaladas (`pytest`, `pytest-asyncio` y `ruff` en el grupo `dev`).
Que una librería esté instalada no significa que su capacidad esté implementada:
`PyJWT`, `pwdlib`, `httpx` y `structlog` todavía no se usan en ningún sitio.

Se utiliza Psycopg 3 (`psycopg`), con el extra `binary` para instalar su distribución
precompilada. SQLAlchemy usará una URL `postgresql+psycopg://` con
`create_async_engine`. Para contraseñas se utiliza `pwdlib[argon2]`.
`httpx` se declara en ejecución porque también se prevén integraciones externas.

Referencias: [dependencias con uv](https://docs.astral.sh/uv/concepts/projects/dependencies/),
[instalación de Psycopg](https://www.psycopg.org/psycopg3/docs/basic/install.html#binary-installation)
y [dialecto Psycopg de SQLAlchemy](https://docs.sqlalchemy.org/en/20/dialects/postgresql.html#module-sqlalchemy.dialects.postgresql.psycopg).

> Estado real hoy: **backend completo** (fases 0 a 9 de [`ROADMAP.md`](ROADMAP.md)).
> Los 11 módulos tienen persistencia, servicio, repositorio, esquemas y router; hay
> infraestructura transversal (`security`, `pagination`, `logging`, `ratelimit`,
> errores 401/403/429/413/500), 119 tests contra PostgreSQL real, Dockerfile,
> `docker-compose.yml` y CI. Lo único externo que falta para operar es Ollama
> (opcional: sin él el coach responde 503 y el resto funciona).

## 2. Qué significa "modular" aquí

Un **monolito modular**: un solo despliegue, dividido en módulos de negocio
autónomos y con fronteras duras. Cada módulo es dueño de sus rutas, sus esquemas,
sus tablas y sus reglas. El núcleo (`core`) no sabe nada de los módulos; los
módulos no se conocen entre sí salvo por su API pública.

## 3. Estructura de carpetas

Lo marcado con ✅ existe; el resto es la forma que debe tomar el código.

```
alembic.ini                  ✅ script_location + logging (la URL NO va aqui)
.env.example                 ✅ plantilla; el .env real no se versiona
database/
├── cieu_schema_completo.sql ✅ esquema de REFERENCIA vigente (42 tablas, pgvector)
└── EmprendeU_postgresql.sql ✅ modelo exportado de EA: referencia historica
src/emprendeu/
├── __init__.py              ✅
├── main.py                  ✅ create_app(): unica app FastAPI + /health
├── core/                       infraestructura transversal, SIN reglas de negocio
│   ├── config.py            ✅ Settings (pydantic-settings), leidos de entorno
│   ├── errors.py            ✅ DomainError + handlers del formato de error global
│   ├── security.py          ✅ hashing (pwdlib/argon2) y JWT (PyJWT, HS256)
│   ├── ratelimit.py         ✅ limitador de intentos (login) en memoria
│   ├── client_ip.py         ✅ IP real del cliente detras de un proxy de confianza (TRUSTED_PROXIES)
│   ├── pagination.py        ✅ Page[T] y PageParams (?page=&page_size=)
│   └── logging.py           ✅ structlog + middleware X-Request-ID
├── db/
│   ├── base.py              ✅ Base declarativa con MetaData(schema="cieu")
│   ├── session.py           ✅ engine async + dependencia get_session
│   ├── metadata.py          ✅ unico punto que importa los modelos de los 11 modulos
│   ├── seed.py              ✅ datos de demostracion (una vez, solo con la base vacia); ver database/SEED.md
│   └── migrations/          ✅ Alembic (plantilla async)
│       ├── env.py           ✅ URL desde Settings, include_schemas, CREATE SCHEMA
│       ├── script.py.mako   ✅ plantilla ajustada para pasar ruff
│       └── versions/        ✅ baseline + usuario (ultimo_acceso, CHECK) + semilla de roles/permisos
├── modules/                 ← TODO el negocio, uno por dominio
│   └── <module>/
│       ├── __init__.py      ✅ API PUBLICA del modulo
│       ├── models.py        ✅ modelos de persistencia (SQLAlchemy)
│       ├── router.py           APIRouter: HTTP puro (status, params, respuestas)     [users ✅]
│       ├── schemas.py          modelos Pydantic de entrada/salida                      [users ✅]
│       ├── repository.py       acceso a datos: unico sitio con queries                 [users ✅]
│       ├── service.py          reglas de negocio y orquestacion                        [users ✅]
│       ├── dependencies.py     dependencias FastAPI propias del modulo                 [users ✅]
│       ├── exceptions.py       errores de dominio del modulo                           [users ✅]
│       ├── permissions.py      (solo users) catalogo de permisos `modulo:accion`       [users ✅]
│       └── tests/                                                                      [users ✅]
├── shared/                     utilidades reutilizables sin negocio
└── api/
    └── v1.py                ✅ APIRouter raiz /api/v1: agrega los routers
tests/                       ✅ tests de integracion end-to-end de la API (+ conftest.py raiz con la BD de pruebas)
```

## 3b. Los 11 modulos y sus tablas

Las 38 tablas originales del schema `cieu` (y 4 nuevas, marcadas con `*`) estan repartidas asi. Nombres de modulo en
ingles; nombres de tabla y columna en espanol, porque los fija la base.

| Modulo | Tablas |
|---|---|
| `users` | `usuario`, `rol`, `permiso`, `rol_permiso`, `rol_usuario`, `restablecimientos_password`* |
| `entrepreneurs` | `emprendedor`, `emprendimiento_emprendedores`, `postulaciones`* |
| `ventures` | `emprendimiento`, `etapas`, `emprendimiento_etapas`, `hito`, `necesidades`, `emprendimiento_necesidades` |
| `mentoring` | `tipo`, `sesiones_acompanamiento`, `sesion_participantes`, `compromisos`, `seguimientos`, `recomendaciones`, `asignaciones`, `perfil_mentor`*, `disponibilidad_mentor`* |
| `training` | `capacitaciones`, `capacitacion_participantes` |
| `gamification` | `insignias`, `emprendedor_insignias`, `retos`, `emprendimiento_retos`, `movimientos_xp` |
| `ai_assistant` | `conversaciones_ia`, `mensajes_ia`, `analisis_sentimiento`, `documentos_conocimiento`, `fragmentos_documento` |
| `indicators` | `tipos_indicadores`, `valores_indicadores` |
| `alerts` | `tipos`, `alertas`, `parametros_seguimiento`* |
| `documents` | `documentos` |
| `audit` | `bitacora` |

Al anadir un modulo: registrarlo en esta tabla, en `db/metadata.py` y, si expone
HTTP, en `api/v1.py`.

> `tipo` (catalogo de tipos de sesion, modulo `mentoring`) y `tipos` (catalogo de
> tipos de alerta, modulo `alerts`) son **tablas distintas**. Para que SQLAlchemy no
> tenga dos clases con el mismo nombre en el registro, la de `alerts` se llama
> `TipoAlerta`.

## 3c. Como se mapea una tabla

La base manda. Al tocar `models.py` se siguen estas reglas, que son las que hacen
que el esquema generado coincida con el de referencia:

- **Clase** en `PascalCase` singular; `__tablename__` en minusculas, tal como
  PostgreSQL normaliza el SQL (`emprendimiento_etapas`).
- **Atributo legible, columna explicita** cuando difieren:
  `emprendimiento_id: Mapped[int] = mapped_column("emprendimientoid", BigInteger, Identity(always=False), primary_key=True)`.
- **Nulabilidad por anotacion**: `Mapped[str]` es `NOT NULL`, `Mapped[str | None]` es nullable.
- **Tipos**: `BIGINT`→`BigInteger`, `VARCHAR(n)`→`String(n)`, `TEXT`→`Text`,
  `TIMESTAMPTZ`→`DateTime(timezone=True)`, `NUMERIC(p,s)`→`Numeric(p,s)`,
  `JSONB`→`postgresql.JSONB`, `BOOLEAN`→`Boolean`, `INTEGER`→`Integer`.
- **`DEFAULT CURRENT_TIMESTAMP`** → `server_default=func.current_timestamp()`.
- **Orden de columnas igual al de la tabla**, para que los `pg_dump` sean comparables.
- **Todo constraint e indice con nombre explicito** en `__table_args__`
  (`fk_`, `uq_`, `ix_`, `ck_`, y los `*_check` que genero PostgreSQL). Por eso
  `db/base.py` **no** define `naming_convention`: los nombres existentes no siguen
  un patron unico y una convencion los renombraria.
- **Un `CheckConstraint` va en `__table_args__`, nunca dentro de `mapped_column`.**
  Dentro de la columna se queda en `column.constraints`, que Alembic no lee, y la
  migracion sale sin el CHECK.
- **Maximo 63 caracteres** por identificador: PostgreSQL los trunca en silencio y
  SQLAlchemy lanza `IdentifierError`. Hay un nombre ya truncado en el esquema:
  `uq_fragmentos_documento_documentos_conocimientoid_numero_fragme`.
- **FK entre modulos por string** (`ForeignKey("emprendimiento.emprendimientoid", ...)`),
  nunca importando el modelo del otro modulo. `MetaData(schema="cieu")` resuelve el
  prefijo del schema.
- **`relationship()` solo dentro del mismo modulo.** Navegar entre modulos es tarea
  de la capa de servicio.

## 4. Estado de los módulos y endpoints

Todos cuelgan de `/api/v1`. `✅` = completo y con tests (`tests/test_*_api.py`).

| Módulo | Endpoints principales |
|---|---|
| `users` ✅ | `POST /auth/login`, `/auth/register`, `/auth/change-password`, `/auth/forgot-password` y `/auth/reset-password` (código de 6 dígitos por correo), `GET /auth/me`; `GET/POST /users`, `PATCH /users/{id}/estado`, `/users/{id}/rol`; `GET/POST /roles`, `PATCH/DELETE /roles/{id}` (solo roles personalizados), `GET/PUT /roles/{id}/permissions` |
| `audit` ✅ | `GET /audit`, `GET /audit/export` (CSV); `AuditService.record(...)` para el resto de módulos |
| `entrepreneurs` ✅ | `GET/POST /entrepreneurs` (el alta crea usuario + emprendedor), `/entrepreneurs/me` (GET/PATCH), `/entrepreneurs/{id}` |
| `ventures` ✅ | `/stages`, `/ventures` (CRUD, `/me`, `PUT /{id}/stage`, historial), equipo (`GET/POST /ventures/{id}/members`, `PATCH/DELETE /ventures/{id}/members/{emprendedor_id}`), hitos (`/milestones`), necesidades (`/needs`) |
| `gamification` ✅ | `/challenges`, `/badges` (catálogo), `GET /journey`, `POST /journey/challenges/{id}/complete` (cuerpo opcional con evidencia; 422 `criteria_not_met` si el reto la exige y falta), `GET /gamification/me` |
| `mentoring` ✅ | `/mentoring/mentors` (+ `PUT {id}/enabled`, perfil, `slots`, horarios: `GET/PUT/POST {id}/availability`, `PATCH/DELETE /availability/{id}`), `booking-status`, `sessions` (agendar, `me` y lista con filtros `estado/desde/hasta`, `register`, completar, cancelar), `commitments` (`POST`, `me`), `recommendations` (`POST`, `me`), `progress`, `POST /mentoring/sync`, `assignments`, historial `GET /mentoring/ventures/{id}/history` y `/ventures/me/history` |
| `alerts` ✅ | `GET/PUT /alerts/settings`, `GET /alerts`, `PATCH /alerts/{id}` (`revisada`, `atendida`, `descartada`), `POST /alerts/evaluate`; tarea `alerts/jobs.py` |
| `indicators` ✅ | `GET /indicators/overview` (resumen del panel), `GET /indicators/health` (puntaje de salud), `GET /indicators/dashboard` (filtros `desde`, `hasta`, `etapa_id`), `GET /indicators/reports/{kind}` y `/export` (CSV) con `kind` ∈ `resumen`, `sesiones`, `alertas`, `indicadores`; tipos y valores por emprendimiento |
| `ai_assistant` ✅ | `POST /ai/chat`, `GET /ai/conversations/me` y `/{id}/messages`, `GET/POST /ai/knowledge` (texto), `POST /ai/knowledge/upload` (archivo txt/md/pdf/docx), `DELETE /ai/knowledge/{id}` (desactivar), `GET /ai/knowledge/index` y `GET /ai/knowledge/{id}/fragments` (índice descargable del coach local, paginado), `GET /ai/knowledge/gaps` (preguntas sin respuesta agrupadas), `GET /ai/status`, `GET /ai/sentiment/{emprendedor_id}` |
| `training` ✅ | `/training` (CRUD, `me`, inscripción, participantes, asistencia) |
| `documents` ✅ | `POST /documents` (multipart, `emprendimiento_id` y `hito_id` opcionales), listado (filtros `emprendimiento_id`, `hito_id`), `download`, `DELETE` |

### Convenciones que ya están fijadas en el código

- **`__init__.py` de cada módulo** exporta modelos y servicio(s); **no** importa el
  `router` (evita ciclos con `users`). `api/v1.py` importa `modules.<m>.router`.
- **Comunicación entre módulos solo por servicio público.** Ningún módulo importa
  `.models`, `.repository` ni `.exceptions` de otro (comprobado con un script).
  Cuando hace falta leer una tabla ajena de forma ligera (nombre del actor en
  `audit`, nombre/correo en `entrepreneurs`) se usa `sqlalchemy.table(...)` y no el modelo.
- **Orden de dependencias entre módulos:** `audit`, `entrepreneurs` → `users` →
  `ventures` → `gamification` → `mentoring` → `ai_assistant` → `alerts` → `indicators`.
  `training` y `documents` solo dependen de `entrepreneurs`/`audit`/`users`.
- **Alcance por rol:** los permisos `modulo:accion` mandan, pero un **emprendedor
  solo ve sus propios emprendimientos** aunque la matriz le dé `consulta`.
  `CurrentUser.can_staff(permiso)` y `require_staff_permission(...)` expresan
  «permiso del rol **y** no ser emprendedor». Las acciones sobre lo propio
  (agendar, cumplir retos, registrar avances) solo exigen estar autenticado y ser miembro.
- **Servicios sin `Request`.** Cada servicio recibe `AsyncSession` (y, si hace falta,
  `LLMClient`) y hace su propio `commit`. `AuditService.record` no hace commit: lo
  hace quien lo llama, para que el cambio y su bitácora vayan en la misma transacción.
- **IA detrás de `LLMClient`** (`ai_assistant/llm.py`): Ollama en producción, un doble
  (`tests/fakes.py`) en tests, inyectado con `dependency_overrides[get_llm]`.
- **Archivos** en disco local (`documents/storage.py`, `UPLOAD_DIR`), con nombre
  generado, lista blanca de extensiones y tope de tamaño. Además de la extensión se comprueba la
  **firma del contenido** (`content_matches`: PDF, imágenes, Office; en texto, sin bytes nulos): un
  archivo renombrado responde el mismo 415 `file_type_not_allowed` y no queda en disco.
- **IP del cliente** (`core/client_ip.py`): los límites por IP (login, recuperación, postulaciones)
  usan `client_ip(request)`, no `request.client.host`. La web llama a la API desde su servidor y
  reenvía la IP del visitante en `X-Forwarded-For`; esa cabecera solo se cree si quien conecta está
  en `TRUSTED_PROXIES` (IPs o redes CIDR; por defecto `127.0.0.1` y `::1`). Si la web corre en otra
  máquina, o la API en Docker, hay que agregar ahí la IP o la red desde la que llega; si no, todas
  las personas de la web comparten un solo contador.
- **Secreto JWT:** en **todos** los entornos la API no arranca si `JWT_SECRET` tiene menos de
  32 caracteres o es el de `.env.example` (`core/config.py`). `ENVIRONMENT=production` además
  desactiva `/docs` y `/redoc`. Errores inesperados devuelven `internal_error` sin detalles.
- **Zona horaria de negocio** `APP_TIMEZONE` (por defecto `America/La_Paz`) solo para
  la agenda de mentorías; todo lo demás se guarda y expone en UTC.

### Datos sembrados con tildes

Las semillas originales iban sin tildes; la migración `c4d6e8f0a1b3` las corrige (etapas,
retos, insignias, tipos de sesión y descripciones de rol). Las **claves técnicas** (nombre
de rol, de permiso y de acción de auditoría) siguen sin tildes; el texto visible
(`audit/catalog.py`, nombres de servicios del resumen) ya lleva tildes. Los mensajes de
error del backend aún van sin tildes: los clientes traducen los códigos que muestran.

### Operación

- Datos de demostración: `uv run python -m emprendeu.db.seed` (solo si `usuario` está vacía; no corre con
  `ENVIRONMENT=production`). En Docker lo hace el servicio `seed` (desactivable con `SEED_DEMO_DATA=false`).
  Cuentas de prueba y contenido en `database/SEED.md`. `db/seed.py` importa los modelos de varios módulos,
  igual que `db/metadata.py`: ningún módulo lo importa.
- Migraciones: `uv run alembic upgrade head` (en Docker, `docker compose run --rm migrate`).
- Primer administrador: `uv run python -m emprendeu.modules.users.cli create-admin ...`.
- Detección de alertas: `uv run python -m emprendeu.modules.alerts.jobs`, o `POST /alerts/evaluate`
  (solo `config:administrativo`). En Docker corre el servicio `alerts-job` del `docker-compose.yml`
  (una pasada cada `ALERTS_INTERVAL_SECONDS`, 86400 por defecto); fuera de Docker, un cron diario.
- Limitador de login en memoria (borra las claves sin intentos vigentes): válido para **un** proceso; con varias réplicas hay que
  moverlo a un almacén compartido (la interfaz no cambia).

### Decisiones de diseño tomadas durante la construcción

- **Roles** (`rol.nombre`): `administrador`, `coordinador`, `asesor`, `emprendedor`.
  El registro publico (`POST /auth/register`) siempre crea un `emprendedor`; el resto
  los crea un administrador con `POST /users`.
- **Permisos** = `modulo:accion` (7 modulos x 4 acciones: consulta, registro,
  modificacion, administrativo), sembrados por la migracion `7a1c4f2b9d30` con la
  matriz por defecto del diseño. Los routers los exigen con `require_permission(...)`
  (exportado por `modules.users`).
- **Cuenta**: `usuario.estado` ∈ {`habilitada`, `deshabilitada`} (CHECK). Un token de
  una cuenta deshabilitada se rechaza en cada peticion (403 `account_disabled`).
- **JWT de acceso unico** (sin refresh), vida `ACCESS_TOKEN_EXPIRE_MINUTES` (60 por
  defecto). `JWT_SECRET` es obligatorio y sin valor por defecto.
- **Recuperación de contraseña (CU01):** `POST /auth/forgot-password {email}` responde 202 con el mismo mensaje exista o no
  la cuenta (sin enumeración) y, si está habilitada, guarda un código de 6 dígitos **hasheado** en
  `restablecimientos_password` (vence en `RESET_CODE_TTL_MINUTES`, 15) y lo envía por SMTP (`core/mailer.py`, `aiosmtplib`,
  detrás de `Mailer` como `LLMClient`; doble `FakeMailer` en `tests/fakes.py`). Un código nuevo anula los anteriores y hay límite de
  solicitudes por IP+correo (429). `POST /auth/reset-password {email, codigo, password_nueva}`: código malo, vencido o usado es 400
  `invalid_code`; a los `RESET_MAX_ATTEMPTS` fallos el código se invalida. Al restablecer se usa `set_password`, así los tokens anteriores
  dejan de valer, y queda en auditoría (`usuarios.restablecer_clave`). Sin `SMTP_HOST` o con el servidor caído: 503 `email_unavailable`.
  En desarrollo, `docker compose --profile mail up` levanta Mailpit (UI en `:8025`).
- **Cambio de contraseña:** `POST /auth/change-password` guarda `usuario.password_changed_at`,
  devuelve una sesión nueva (`TokenResponse`) y desde ese instante `UserService.authenticate`
  rechaza (401) todo token emitido antes. El token lleva `iat_us` (microsegundos): `iat` solo
  tiene segundos y no distingue un token del mismo segundo del cambio. Una contraseña actual
  equivocada responde **400** `wrong_password` (no 401, que los clientes tratan como sesión vencida).
- La referencia vigente es `database/cieu_schema_completo.sql` (`EmprendeU_postgresql.sql`
  es historia). La migración `f33df1970606` alineó el esquema con ella; `alembic check` queda
  limpio y una comparación de columnas, restricciones e índices contra una base creada desde ese
  SQL no da diferencias. El SQL incluye además las columnas que el código ya usaba:
  `usuario.ultimo_acceso`, CHECK `ck_usuario_estado` y default de `usuario.estado`;
  `retos.orden`; `seguimientos.referencia_cliente` (+ único por usuario) y
  `perfil_mentor.reto_requeridoid`. La semilla de roles, permisos, etapas, retos, insignias,
  tipos y parámetros vive en las migraciones, no en el SQL (una base creada solo con el SQL
  queda sin roles).
- `perfil_mentor` lleva `habilitado` (solo un asesor habilitado recibe asignaciones y agendas).
  `disponibilidad_mentor` son **intervalos concretos** sin solapamiento (restricción de exclusión
  de PostgreSQL); `mentoring/service.py` los reparte en turnos de `SLOT_MINUTES` (60).
- `parametros_seguimiento` es **clave-valor** (`alerts/repository.py: SETTING_KEYS`). El servicio
  convierte entre las claves y los campos tipados de `GET/PUT /alerts/settings`, que no cambiaron.
  La caída de sentimiento se guarda como umbral decimal negativo (`-0.25` = 25 %).
- `compromisos` guarda quién registra (`registrado_por_usuarioid`), quién responde
  (`responsable_usuarioid`) y el `emprendimientoid`; la sesión es opcional y, si existe, debe ser
  del mismo emprendimiento (FK compuesta).
- **Reglas de mentorías** (`mentoring/service.py`): solo un asesor **habilitado** recibe asignaciones y
  agendas, y asignar o habilitar es de coordinación (el rol `asesor` tiene `asesorias:registro`, pero
  recibe 403). No se duplica una asignación activa (409 `assignment_exists`). El emprendedor ve y
  agenda solo con asesores asignados y habilitados (403 `mentor_not_assigned`). Un asesor registra
  sesiones, recomendaciones y compromisos solo en emprendimientos que tiene asignados (403
  `not_assigned`); coordinación no tiene esa restricción. El horario que se solapa da 409
  `availability_overlap` y no guarda nada (la base lo impide con una restricción de exclusión).
  La fecha de una sesión realizada no puede ser futura (422 `future_date`); recomendación y
  compromiso con `sesion_id` exigen que la sesión sea del mismo emprendimiento (422
  `session_mismatch`); el responsable del compromiso es un emprendedor del emprendimiento o un asesor
  asignado (422 `responsible_not_member`) y, sin fecha límite, se usa `dias_limite_compromiso`
  (leído de `parametros_seguimiento` con `sqlalchemy.table`, sin importar el módulo `alerts`). Los
  filtros de periodo comparan con la **fecha en que ocurrió** (realizada si existe, si no la agendada).
- **Seguimiento (fase 3):** `PUT /ventures/{id}/stage` solo acepta la **siguiente etapa activa** por
  `etapas.orden` (la primera si aún no tiene etapa; 409 `invalid_stage_transition`, con `details.siguiente`);
  repetir la actual no hace nada y el historial conserva las anteriores. Las alertas son `abierta` →
  `revisada` (sigue pendiente) → `atendida` o `descartada` (cierran, 409 `alert_closed`); `atendida` guarda
  `alertas.atendida_por_usuarioid` y un asesor solo toca alertas de emprendimientos asignados. Listar y
  gestionar alertas es solo para personal (`seguimiento:*` y no ser emprendedor). `dias_limite_compromiso`
  (1–90) es otra clave de `parametros_seguimiento`; cambiar parámetros y generar reportes se audita
  (`negocio.alerta`, `negocio.reporte`). Periodos: `core/periods.py`; CSV con BOM: `core/csv_export.py`.
  El historial une sesiones, avances, hitos, recomendaciones, compromisos y etapas (los sin fecha van al final).
- **Emprendedores y emprendimientos (fase 4):** `POST /entrepreneurs` (coordinación) crea la cuenta, el perfil y el
  documento en **una transacción** (`UserService.register_entrepreneur`, porque `users` depende de `entrepreneurs`
  y no al revés); devuelve la clave temporal una sola vez. El documento de identidad es único sin distinguir
  mayúsculas ni espacios (409 `document_already_registered`), también al editar el perfil propio. **Esa unicidad
  se valida en el servicio: el esquema de referencia no define un índice único sobre `emprendedor.documento_identidad`.**
  El personal con `emprendedores:registro` crea un emprendimiento **con su equipo**: `integrantes` (1 a 20, rol
  `fundador`/`cofundador`/`miembro`; `emprendedor_id` es el atajo de uno solo, como fundador; 422 `entrepreneur_required`
  si no hay ninguno, `duplicate_member`, `entrepreneur_not_found`); un emprendedor solo crea los suyos y queda como
  fundador. El equipo lo gestiona solo el personal con `emprendedores:modificacion` (409 `already_member`, 404
  `member_not_found`, 409 `last_member`: nunca queda vacío) y cada `VentureOut` trae `integrantes`. **Un emprendedor
  puede estar en varios emprendimientos**: sus endpoints aceptan `emprendimiento_id` (también `POST /ai/chat` para una
  conversación nueva) y, sin indicarlo, usan el primero (`EntrepreneurRef.primary_venture_id`). Un emprendedor edita el suyo pero el
  `estado` es campo reservado (403 `reserved_fields`, `details.campos`). El camino de un emprendimiento
  (`GET /journey?emprendimiento_id=`) lo ve cualquier personal con `seguimiento:consulta`; cumplir retos es solo del
  emprendedor miembro. La evidencia de un hito se sube con `POST /documents` + `hito_id`: el hito debe ser del mismo
  emprendimiento (422 `milestone_mismatch`).
- **Coach IA y base de conocimiento (fase 5):** un documento pasa por `procesando` → `activo`, o `error` si el
  modelo de embeddings no responde (queda registrado, sin fragmentos, y la petición responde 503); `inactivo` lo retira.
  **Solo los `activo` alimentan al coach.** El procesamiento es síncrono dentro de la petición (el documento se confirma
  como `procesando` antes de calcular los embeddings). Administrar la base exige `config:modificacion` (coordinación y
  administración). El archivo se lee con `extraction.py` (`pypdf`, `python-docx`); formato no permitido 415, archivo
  ilegible o sin texto 422, más de `MAX_UPLOAD_MB` 413. El coach busca con distancia coseno (`<=>`, índice HNSW), pasa al
  modelo solo los fragmentos con similitud >= `AI_MIN_SIMILARITY` (0.65, calibrado con una muestra pequeña de preguntas y documentos reales: ajústalo si cambias de modelo o de corpus) y, si no hay ninguno, responde el mensaje de
  información insuficiente **sin consultar al modelo** y sugiere un mentor (`derivar_mentor`). Si Ollama cae durante un
  chat se hace `rollback` de todo (conversación nueva, pregunta y sentimiento): nada queda a medias (503
  `ai_unavailable`). **RF07:** `analisis_sentimiento` guarda solo el índice numérico, la fecha y el emprendedor, sin texto y
  **sin enlace al mensaje** (`mensajes_iaid` queda nulo); el personal ve únicamente la serie semanal agregada.
- **Índice descargable del coach local (móvil):** `GET /ai/knowledge/index` (`ia:consulta`) devuelve
  `modelo_embeddings`, `dimension` y los documentos `activo` con fragmentos; el móvil compara con lo que
  ya tiene (descarga los nuevos, borra los que faltan; no hace falta columna de fecha de cambio).
  `GET /ai/knowledge/{id}/fragments` entrega `numero_fragmento`, `contenido` y `embedding` paginados
  (404 `knowledge_not_found` si el documento no está `activo`); con `incluir_embedding=false` el
  `embedding` va `null`. **El móvil usa esa opción**: su motor no ejecuta `nomic-embed-text`, así que
  recalcula los vectores con EmbeddingGemma en el celular (no hace falta otra columna ni migración). `ChatReply.fuentes_detalle` añade
  `documento_conocimiento_id` a cada fuente; `fuentes` (títulos) se mantiene por compatibilidad.
- **Brechas de la base (preguntas sin respuesta):** cada respuesta del asistente guarda `mensajes_ia.con_fuente`
  (`false` = respondió «no encontré información»; la migración `dd8b7041296c` rellenó las anteriores comparando con
  ese texto). `GET /ai/knowledge/gaps?desde=&hasta=` (`config:consulta`, 90 días por defecto) toma la pregunta del
  usuario previa a cada respuesta sin fuente y las agrupa por similitud de embeddings (umbral 0,8, voraz); si el
  modelo no responde, agrupa por texto igual sin tildes ni signos (`por_similitud=false`). **Anónimo:** solo el texto
  de la pregunta y la fecha. Lo de la IA del celular no llega al servidor, así que no se cuenta.
- **Puntaje de salud** (`indicators/health.py`, función pura `score_venture`): parte de 100 y resta por alertas sin
  resolver (10 c/u, tope 30), compromisos vencidos (8 c/u, tope 24), inactividad pasada `dias_inactividad` (10; 20 si
  es el doble; misma «última actividad» que la alerta, `AlertService.last_activity_by_venture`), días en la etapa
  activa (≥ 120: 10; ≥ 180: 15) y ánimo del coach de sus emprendedores en 28 días (≤ -0,2: 15; o caída ≥ 0,25 frente
  a los 28 previos: 10). Verde ≥ 70, ámbar 40–69, rojo < 40; cada descuento deja un motivo legible.
  `GET /indicators/health` (`seguimiento:consulta` y ser personal) ordena del menor al mayor; el asesor solo ve
  sus asignaciones activas. Usa solo el índice de sentimiento anónimo (`AssistantService.sentiment_points`).
- La matriz por defecto da a `administrador` solo `asesorias:consulta`: quien registra sesiones y
  gestiona asignaciones es coordinación (`consulta/registro`) y el asesor (`consulta/registro/modificacion`).
- `fragmentos_documento.embedding` es `vector(768)` (pgvector, `EMBEDDING_DIM`); la búsqueda usa
  distancia coseno con índice HNSW. Hay que usar un modelo de 768 dimensiones (nomic-embed-text).
- Las migraciones **no** se ejecutan al arrancar el contenedor: en Docker las corre el servicio
  `migrate` del `docker-compose.yml`; la API depende de que termine bien.
- `Usuario.nombre`/`apellido`: el alta recibe `nombre_completo`; la primera palabra
  es el nombre y el resto el apellido (se exigen al menos dos palabras).

### Tests

`conftest.py` (raiz) crea la base `<nombre>_test`, corre `alembic upgrade head` (asi
se prueban migraciones y semilla) y envuelve cada test en una transaccion que se
revierte. Requiere el PostgreSQL de desarrollo levantado.

## 5. Reglas del backend

1. **Una sola app FastAPI**, creada en `main.py` por `create_app()`. Ningún módulo
   instancia `FastAPI()`.
2. **Dirección de dependencias**: `router → service → repository → models`.
   Estrictamente en ese sentido.
   - `router.py`: **sin** reglas de negocio y **sin** queries. Traduce HTTP ↔ servicio.
   - `service.py`: **sin** objetos `Request`/`Response` y **sin** SQL.
   - `repository.py`: **único** lugar donde hay queries/ORM. Devuelve modelos o
     primitivos, nunca `Response`.
3. **Los modelos de persistencia no salen del módulo.** Lo que cruza la frontera
   HTTP son esquemas Pydantic de `schemas.py`. Nunca devuelvas un modelo ORM.
4. **Comunicación entre módulos**: solo importando desde `modules.<otro>` (su
   `__init__.py`), y solo su *servicio*. Prohibido importar
   `modules.<otro>.repository` o `.models`. Si dos módulos necesitan compartir
   tablas, el diseño está mal: revísalo con el usuario.
5. **`core/` y `shared/` no importan nunca desde `modules/`.** El único agregador
   permitido es `db/metadata.py` (modelos) junto a `api/v1.py` (routers).
6. **Configuración solo por entorno**, vía `core/config.py`. Ningún `os.getenv`
   suelto, ningún secreto en el repositorio.
7. **Errores de dominio** se lanzan como excepciones de `exceptions.py` del módulo
   y se traducen a HTTP en los handlers de `core/errors.py`, respetando el formato
   `{"error": {"code", "message", "details"}}` del contrato global.
8. **Async por defecto** en endpoints y acceso a datos. Nada de I/O bloqueante
   dentro de una corrutina.
9. **Tipado completo**: todas las funciones públicas anotadas; nada de `Any` sin
   justificación en comentario.
10. **Tests junto al módulo** (`modules/<m>/tests/`) para servicio y repositorio;
    `tests/` en la raíz solo para flujos de API completos.
11. **Alembic es la única vía para cambiar el esquema.** Nunca
    `Base.metadata.create_all()`, nunca DDL a mano, nunca editar
    `database/EmprendeU_postgresql.sql`: ese archivo es la referencia histórica del
    modelo exportado de Enterprise Architect y ya no se ejecuta. La referencia vigente es
    `database/cieu_schema_completo.sql`: si el código y ese archivo no coinciden, se reporta
    antes de cambiar cualquiera de los dos. Las migraciones ya aplicadas no se editan.
    El ciclo es: tocar `models.py` → `uv run alembic revision --autogenerate -m "..."`
    → **leer la migración generada** → `uv run alembic upgrade head`. Modelo y
    migración van en el mismo commit.
12. **Antes de dar por buena una migración**, comprobarlo contra una base real:
    `uv run alembic check` debe decir *"No new upgrade operations detected"*, y
    `alembic upgrade head` sobre una base virgen debe funcionar. Alembic no compara
    `server_default` ni los CHECK anónimos, así que una revisión vacía no basta por
    sí sola: si el cambio los toca, compara con `pg_dump --schema-only -n cieu`.
13. **La URL de la base solo vive en el entorno.** `alembic.ini` no lleva
    `sqlalchemy.url`; `db/migrations/env.py` la toma de `core/config.Settings`.
14. **El schema es `cieu`**, nunca `public`. Lo fija `MetaData(schema="cieu")` en
    `db/base.py`; `env.py` lo crea si falta y guarda ahí `alembic_version`.
