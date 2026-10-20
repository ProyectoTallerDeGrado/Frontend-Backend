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

> Estado real hoy: existe la app ASGI, la configuración, el engine async y los
> modelos de las 38 tablas. **No hay nada de HTTP de negocio**: ningún módulo tiene
> `router.py`, `service.py` ni `repository.py`. Ese es el siguiente paso (§4).

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
│   ├── security.py             hashing (pwdlib) y JWT (PyJWT)
│   ├── pagination.py           Page[T] y parametros de paginacion
│   └── logging.py              structlog
├── db/
│   ├── base.py              ✅ Base declarativa con MetaData(schema="cieu")
│   ├── session.py           ✅ engine async + dependencia get_session
│   ├── metadata.py          ✅ unico punto que importa los modelos de los 11 modulos
│   └── migrations/          ✅ Alembic (plantilla async)
│       ├── env.py           ✅ URL desde Settings, include_schemas, CREATE SCHEMA
│       ├── script.py.mako   ✅ plantilla ajustada para pasar ruff
│       └── versions/        ✅ migracion base con las 38 tablas
├── modules/                 ← TODO el negocio, uno por dominio
│   └── <module>/
│       ├── __init__.py      ✅ API PUBLICA del modulo
│       ├── models.py        ✅ modelos de persistencia (SQLAlchemy)
│       ├── router.py           APIRouter: HTTP puro (status, params, respuestas)
│       ├── schemas.py          modelos Pydantic de entrada/salida
│       ├── repository.py       acceso a datos: unico sitio con queries
│       ├── service.py          reglas de negocio y orquestacion
│       ├── dependencies.py     dependencias FastAPI propias del modulo
│       ├── exceptions.py       errores de dominio del modulo
│       └── tests/
├── shared/                     utilidades reutilizables sin negocio
└── api/
    └── v1.py                ✅ APIRouter raiz /api/v1: agrega los routers
tests/                          tests de integracion end-to-end de la API
```

## 3b. Los 11 modulos y sus tablas

Las 38 tablas del schema `cieu` estan repartidas asi. Nombres de modulo en
ingles; nombres de tabla y columna en espanol, porque los fija la base.

| Modulo | Tablas |
|---|---|
| `users` | `usuario`, `rol`, `permiso`, `rol_permiso`, `rol_usuario` |
| `entrepreneurs` | `emprendedor`, `emprendimiento_emprendedores` |
| `ventures` | `emprendimiento`, `etapas`, `emprendimiento_etapas`, `hito`, `necesidades`, `emprendimiento_necesidades` |
| `mentoring` | `tipo`, `sesiones_acompanamiento`, `sesion_participantes`, `compromisos`, `seguimientos`, `recomendaciones`, `asignaciones` |
| `training` | `capacitaciones`, `capacitacion_participantes` |
| `gamification` | `insignias`, `emprendedor_insignias`, `retos`, `emprendimiento_retos`, `movimientos_xp` |
| `ai_assistant` | `conversaciones_ia`, `mensajes_ia`, `analisis_sentimiento`, `documentos_conocimiento`, `fragmentos_documento` |
| `indicators` | `tipos_indicadores`, `valores_indicadores` |
| `alerts` | `tipos`, `alertas` |
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

## 4. Orden de construccion (siguiente paso)

La capa de datos esta lista. Falta el HTTP:

1. `core/security.py` (hash con `pwdlib`, JWT con `PyJWT`) y `core/pagination.py`.
2. Primer modulo completo de punta a punta, probablemente `users` o `auth`:
   `repository.py` → `service.py` → `schemas.py` → `router.py`, registrado en
   `api/v1.py`. Sirve de plantilla para los demas.
3. `core/logging.py` con structlog.
4. Tests: `modules/<m>/tests/` para servicio y repositorio, `tests/` para la API.

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
