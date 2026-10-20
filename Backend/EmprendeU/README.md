# Backend EmprendeU

API en Python 3.13 con FastAPI y arquitectura de monolito modular.
Lee [AGENTS.md](AGENTS.md) antes de crear archivos o implementar módulos: define la
estructura, el reparto de las 38 tablas en módulos y las reglas de mapeo del ORM.

## Puesta en marcha

```bash
cd Backend/EmprendeU

# 1. Dependencias (ejecución + dev) desde el lockfile
uv sync --locked

# 2. PostgreSQL de desarrollo
docker run -d --name emprendeu-db \
  -e POSTGRES_USER=emprendeu -e POSTGRES_PASSWORD=emprendeu -e POSTGRES_DB=emprendeu \
  -p 5432:5432 postgres:17-alpine

# 3. Configuración
cp .env.example .env        # ajustar DATABASE_URL si hace falta

# 4. Crear el schema cieu y las 38 tablas
uv run alembic upgrade head

# 5. Levantar la API
uv run uvicorn emprendeu.main:app --reload --port 8000
```

Comprobación rápida: `curl http://127.0.0.1:8000/health` devuelve
`{"status":"ok","database":"ok"}`, y el contrato queda en
`http://127.0.0.1:8000/api/v1/openapi.json`.

## Base de datos

- **ORM**: SQLAlchemy 2.x en modo async. Los modelos están en
  `src/emprendeu/modules/<módulo>/models.py`, uno por dominio, sobre la `Base` de
  `src/emprendeu/db/base.py` (`MetaData(schema="cieu")`).
- **Creación de tablas**: **solo Alembic**. Nunca `create_all()` ni DDL a mano.
- **Driver**: psycopg 3, con URL `postgresql+psycopg://`.
- `database/EmprendeU_postgresql.sql` es el modelo exportado de Enterprise
  Architect. Queda como **referencia histórica**: ya no se ejecuta, y los modelos
  del ORM reproducen su esquema exactamente (verificado con `pg_dump`, esquemas
  idénticos).

### Cambiar el esquema

```bash
# 1. editar el models.py del módulo correspondiente
uv run alembic revision --autogenerate -m "descripcion del cambio"
# 2. LEER la migración generada en src/emprendeu/db/migrations/versions/
uv run alembic upgrade head
uv run alembic check          # debe decir: No new upgrade operations detected
```

Cuidado con dos cosas que cuestan tiempo si se pasan por alto:

- Un `CheckConstraint` dentro de `mapped_column(...)` **no** aparece en la
  migración (se queda en la columna, y Alembic lee `table.constraints`). Va en
  `__table_args__`, con nombre.
- Los identificadores tienen un máximo de 63 caracteres. PostgreSQL los trunca en
  silencio, pero SQLAlchemy lanza `IdentifierError`.

## Verificar y ejecutar

```bash
uv run ruff check src/
uv run ruff format --check src/
uv run pytest                 # cuando existan pruebas
```

## Estado actual

Hecho: configuración por entorno, engine y sesión async, handlers del formato de
error global, app ASGI con `/health`, y los modelos de las 38 tablas del schema
`cieu` en 11 módulos con su migración base.

Pendiente: todo el HTTP de negocio (`router.py`, `service.py`, `repository.py`,
`schemas.py` por módulo), autenticación (`PyJWT` y `pwdlib` están instalados pero
sin usar), logging con structlog, paginación y las pruebas.

Referencias: [dependencias con uv](https://docs.astral.sh/uv/concepts/projects/dependencies/),
[SQLAlchemy con Psycopg](https://docs.sqlalchemy.org/en/20/dialects/postgresql.html#module-sqlalchemy.dialects.postgresql.psycopg)
y [Alembic con async](https://alembic.sqlalchemy.org/en/latest/cookbook.html#using-asyncio-with-alembic).
