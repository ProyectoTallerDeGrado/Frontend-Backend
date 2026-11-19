k# Backend EmprendeU

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
  -p 5432:5432 pgvector/pgvector:pg17     # imagen con pgvector (busqueda semantica del asistente)

# 3. Configuración
cp .env.example .env        # ajustar DATABASE_URL si hace falta

# 4. Crear el schema cieu y las 42 tablas (necesita las extensiones vector y btree_gist;
#    la imagen de arriba las trae y el usuario del contenedor puede crearlas)
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
- `database/cieu_schema_completo.sql` es la **referencia vigente** del esquema (42 tablas,
  pgvector). El esquema real sale de las migraciones y coincide con ella (comparado columna
  a columna, restricción a restricción). `database/EmprendeU_postgresql.sql` es el modelo
  original exportado de Enterprise Architect: referencia **histórica**, ya no se ejecuta.
- Las migraciones crean las extensiones `vector` y `btree_gist` en el schema `public`: el
  usuario de la base debe poder crearlas (superusuario, o extensiones de confianza).

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
uv run pytest                 # requiere el PostgreSQL de desarrollo (usa <db>_test)
```

## Estado actual

Backend **completo**: 11 módulos con su HTTP, auditoría transversal, 78 tests contra
PostgreSQL real, Dockerfile, `docker-compose.yml` y CI (`.github/workflows/backend.yml`).
El detalle de endpoints está en [AGENTS.md](AGENTS.md) §4 y en `/docs` (solo fuera de producción).

### Primer arranque

```bash
uv run alembic upgrade head
uv run python -m emprendeu.modules.users.cli create-admin \
    --email admin@uagrm.edu.bo --nombre "Nombre Apellido"      # pide la contraseña
uv run uvicorn emprendeu.main:app --reload --port 8000
```http://localhost:3000

### Con Docker

```bash
cp .env.example .env                   # y ajusta POSTGRES_*, JWT_SECRET (>= 32 caracteres) y CORS_ORIGINS
docker compose up --build              # PostgreSQL (pgvector) + migraciones + API
docker compose run --rm migrate        # solo aplicar migraciones
docker compose --profile ai up --build # + Ollama; el servicio `ollama-pull` descarga nomic-embed-text (768 dim.) y llama3.2
```

### Variables de entorno

`DATABASE_URL`, `JWT_SECRET` (obligatoria, mínimo 32 caracteres y distinta de la de ejemplo),
`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `DB_PORT`, `API_PORT` (solo `docker compose`),
`ACCESS_TOKEN_EXPIRE_MINUTES`, `CORS_ORIGINS`,
`ENVIRONMENT`, `LOGIN_MAX_ATTEMPTS`, `LOGIN_WINDOW_SECONDS`, `APP_TIMEZONE`,
`BOOKING_MIN_STAGE_ORDER`, `OLLAMA_BASE_URL`, `OLLAMA_EMBED_MODEL`, `OLLAMA_CHAT_MODEL`,
`UPLOAD_DIR`, `MAX_UPLOAD_MB`. Plantilla en `.env.example`.

### Tarea programada

Alertas de riesgo: `uv run python -m emprendeu.modules.alerts.jobs` (una vez al día). En Docker lo hace el servicio `alerts-job` de `docker-compose.yml` (`ALERTS_INTERVAL_SECONDS`, 86400 por defecto).

### Clientes

- **Web** (`Frontend/emprendeu`): llama al API desde el servidor de Next (`API_URL`), así que
  no necesita CORS. El panel solo admite roles distintos de `emprendedor`.
- **Móvil** (`Frontend/app_emprendeu`): `--dart-define=API_BASE_URL=...` (emulador Android:
  `http://10.0.2.2:8000/api/v1`). Solo admite el rol `emprendedor`.
- `POST /auth/register` siempre crea un **emprendedor**; los demás roles los asigna un
  administrador (`POST /users`, `PATCH /users/{id}/rol`).

Lo pendiente está en [`ROADMAP.md`](ROADMAP.md).
