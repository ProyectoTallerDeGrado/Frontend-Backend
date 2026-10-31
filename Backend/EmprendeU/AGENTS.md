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
| ORM | **SQLAlchemy 2.x async** | en uso: 38 modelos declarativos |
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
> errores 401/403/429/413/500), 52 tests contra PostgreSQL real, Dockerfile,
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
└── EmprendeU_postgresql.sql ✅ modelo exportado de EA: referencia historica
src/emprendeu/
├── __init__.py              ✅
├── main.py                  ✅ create_app(): unica app FastAPI + /health
├── core/                       infraestructura transversal, SIN reglas de negocio
│   ├── config.py            ✅ Settings (pydantic-settings), leidos de entorno
│   ├── errors.py            ✅ DomainError + handlers del formato de error global
│   ├── security.py          ✅ hashing (pwdlib/argon2) y JWT (PyJWT, HS256)
│   ├── ratelimit.py         ✅ limitador de intentos (login) en memoria
│   ├── pagination.py        ✅ Page[T] y PageParams (?page=&page_size=)
│   └── logging.py           ✅ structlog + middleware X-Request-ID
├── db/
│   ├── base.py              ✅ Base declarativa con MetaData(schema="cieu")
│   ├── session.py           ✅ engine async + dependencia get_session
│   ├── metadata.py          ✅ unico punto que importa los modelos de los 11 modulos
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

Las 38 tablas originales del schema `cieu` (y 3 nuevas, marcadas con `*`) estan repartidas asi. Nombres de modulo en
ingles; nombres de tabla y columna en espanol, porque los fija la base.

| Modulo | Tablas |
|---|---|
| `users` | `usuario`, `rol`, `permiso`, `rol_permiso`, `rol_usuario` |
| `entrepreneurs` | `emprendedor`, `emprendimiento_emprendedores` |
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
| `users` ✅ | `POST /auth/login`, `/auth/register`, `/auth/change-password`, `GET /auth/me`; `GET/POST /users`, `PATCH /users/{id}/estado`, `/users/{id}/rol`; `GET /roles`, `GET/PUT /roles/{id}/permissions` |
| `audit` ✅ | `GET /audit`, `GET /audit/export` (CSV); `AuditService.record(...)` para el resto de módulos |
| `entrepreneurs` ✅ | `GET /entrepreneurs`, `/entrepreneurs/me` (GET/PATCH), `/entrepreneurs/{id}` |
| `ventures` ✅ | `/stages`, `/ventures` (CRUD, `/me`, `PUT /{id}/stage`, historial), hitos (`/milestones`), necesidades (`/needs`) |
| `gamification` ✅ | `/challenges`, `/badges` (catálogo), `GET /journey`, `POST /journey/challenges/{id}/complete`, `GET /gamification/me` |
| `mentoring` ✅ | `/mentoring/mentors` (+ perfil, disponibilidad, `slots`), `booking-status`, `sessions` (agendar, `me`, completar, cancelar), `commitments`, `recommendations`, `progress`, `POST /mentoring/sync`, `assignments` |
| `alerts` ✅ | `GET/PUT /alerts/settings`, `GET /alerts`, `PATCH /alerts/{id}`, `POST /alerts/evaluate`; tarea `alerts/jobs.py` |
| `indicators` ✅ | `GET /indicators/overview` (resumen del panel), tipos y valores por emprendimiento |
| `ai_assistant` ✅ | `POST /ai/chat`, conversaciones, `/ai/knowledge` (RAG), `/ai/status`, `/ai/sentiment/{id}` |
| `training` ✅ | `/training` (CRUD, `me`, inscripción, participantes, asistencia) |
| `documents` ✅ | `POST /documents` (multipart), listado, `download`, `DELETE` |

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
  generado, lista blanca de extensiones y tope de tamaño.
- **Producción:** `ENVIRONMENT=production` exige `JWT_SECRET` de 32+ caracteres,
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

- Primer administrador: `uv run python -m emprendeu.modules.users.cli create-admin ...`.
- Detección de alertas: `uv run python -m emprendeu.modules.alerts.jobs` (cron diario),
  o `POST /alerts/evaluate`.
- Limitador de login en memoria: válido para **un** proceso; con varias réplicas hay que
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
- El esquema **ya no coincide** con `database/EmprendeU_postgresql.sql`. Cambios
  posteriores (todos por migración): `usuario.ultimo_acceso`, CHECK `ck_usuario_estado`
  y default de `usuario.estado`; `retos.orden`; `seguimientos.referencia_cliente` (+ único
  por usuario); tablas nuevas `perfil_mentor` y `disponibilidad_mentor` (mentoring) y
  `parametros_seguimiento` (alerts, fila única id = 1); y la semilla de roles, permisos,
  etapas, retos, insignias, tipos y parámetros por defecto.
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
    modelo exportado de Enterprise Architect y ya no se ejecuta.
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
