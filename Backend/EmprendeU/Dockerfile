# Imagen de la API. Build: docker build -t emprendeu-api .
FROM python:3.13-slim AS base

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

COPY --from=ghcr.io/astral-sh/uv:0.12 /uv /usr/local/bin/uv

WORKDIR /app

# Dependencias primero (capa cacheable)
COPY pyproject.toml uv.lock README.md alembic.ini ./
COPY src ./src
RUN uv sync --locked --no-dev

ENV PATH="/app/.venv/bin:$PATH"

RUN useradd --create-home --uid 10001 app && mkdir -p /app/uploads && chown -R app /app/uploads
USER app

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=4).status == 200 else 1)"

# Solo arranca la API. Las migraciones son un paso aparte y se ejecutan una vez:
#   docker compose run --rm migrate      (o: alembic upgrade head)
CMD ["uvicorn", "emprendeu.main:app", "--host", "0.0.0.0", "--port", "8000"]
