"""Verifica que las migraciones de Alembic produzcan el mismo esquema que `cieu_schema_completo.sql`.

Crea dos bases temporales en el servidor indicado:

  1. `verify_ref`: se le aplica `cieu_schema_completo.sql`.
  2. `verify_mig`: se le aplica `alembic upgrade head` desde cero.

Compara el schema `cieu` de ambas (tablas, columnas con tipo, nulabilidad, valor por defecto e
identidad, restricciones e indices) e informa cada diferencia. Termina con codigo 1 si hay alguna.
Al final borra las dos bases temporales (solo esas dos; no toca nada mas).

Uso (desde `Backend/EmprendeU`, con PostgreSQL + pgvector accesible):

    uv run python database/verify_schema.py --admin-url postgresql://usuario:clave@localhost:5432/postgres

La URL no se imprime. Hace falta un usuario que pueda crear bases de datos.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

import psycopg
from psycopg import sql

ROOT = Path(__file__).resolve().parent.parent
SQL_FILE = ROOT / "database" / "cieu_schema_completo.sql"
TEMP_DBS = ("verify_ref", "verify_mig")
SCHEMA = "cieu"
# La tabla de control de Alembic y la semilla (datos) no forman parte del esquema comparado.
IGNORED_TABLES = ("alembic_version",)

COLUMNS = """
SELECT c.relname, a.attname, format_type(a.atttypid, a.atttypmod), a.attnotnull,
       a.attidentity::text, coalesce(pg_get_expr(d.adbin, d.adrelid), '')
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE n.nspname = %s AND c.relkind = 'r' AND a.attnum > 0 AND NOT a.attisdropped
  AND c.relname <> ALL(%s)
"""
CONSTRAINTS = """
SELECT c.relname, con.conname, con.contype::text, pg_get_constraintdef(con.oid)
FROM pg_constraint con
JOIN pg_class c ON c.oid = con.conrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = %s AND c.relname <> ALL(%s)
"""
INDEXES = """
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = %s AND tablename <> ALL(%s)
"""


def with_db(url: str, name: str) -> str:
    parts = urlsplit(url)
    return urlunsplit(parts._replace(path=f"/{name}"))


def sqlalchemy_url(url: str, name: str) -> str:
    return with_db(url, name).replace("postgresql://", "postgresql+psycopg://", 1)


def rows(url: str, query: str) -> set[tuple]:
    with psycopg.connect(url) as conn, conn.cursor() as cur:
        cur.execute(query, (SCHEMA, list(IGNORED_TABLES)))  # type: ignore[arg-type]
        return {tuple(r) for r in cur.fetchall()}


def snapshot(url: str) -> dict[str, set[tuple]]:
    return {
        "columnas": rows(url, COLUMNS),
        "restricciones": rows(url, CONSTRAINTS),
        "indices": rows(url, INDEXES),
    }


def recreate(admin_url: str, name: str) -> None:
    with psycopg.connect(admin_url, autocommit=True) as conn:
        conn.execute(sql.SQL("DROP DATABASE IF EXISTS {}").format(sql.Identifier(name)))
        conn.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(name)))


def drop(admin_url: str, name: str) -> None:
    with psycopg.connect(admin_url, autocommit=True) as conn:
        conn.execute(sql.SQL("DROP DATABASE IF EXISTS {}").format(sql.Identifier(name)))


def apply_reference(admin_url: str) -> str:
    url = with_db(admin_url, "verify_ref")
    with psycopg.connect(url, autocommit=True) as conn:
        conn.execute(SQL_FILE.read_text(encoding="utf-8"))
    return url


def apply_migrations(admin_url: str) -> str:
    env = {
        **os.environ,
        "DATABASE_URL": sqlalchemy_url(admin_url, "verify_mig"),
        # `alembic` exige un secreto valido al cargar la configuracion; este no se usa para nada mas.
        "JWT_SECRET": os.environ.get(
            "JWT_SECRET", "verificacion-de-esquema-" + "x" * 16
        ),
    }
    subprocess.run(
        ["alembic", "upgrade", "head"],
        cwd=ROOT,
        env=env,
        check=True,
        stdout=subprocess.DEVNULL,
    )
    return with_db(admin_url, "verify_mig")


def compare(ref: dict[str, set[tuple]], mig: dict[str, set[tuple]]) -> int:
    problems = 0
    for kind in ref:
        only_ref = sorted(ref[kind] - mig[kind])
        only_mig = sorted(mig[kind] - ref[kind])
        if not only_ref and not only_mig:
            print(f"OK   {kind}: {len(ref[kind])} coinciden")
            continue
        for row in only_ref:
            problems += 1
            print(f"DIFF {kind}: solo en el SQL de referencia -> {row}")
        for row in only_mig:
            problems += 1
            print(f"DIFF {kind}: solo en las migraciones     -> {row}")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--admin-url",
        required=True,
        help="postgresql://usuario:clave@host:puerto/postgres",
    )
    args = parser.parse_args()
    admin_url: str = args.admin_url
    if not SQL_FILE.is_file():
        print(f"No existe {SQL_FILE}", file=sys.stderr)
        return 2
    for name in TEMP_DBS:
        recreate(admin_url, name)
    try:
        ref_url = apply_reference(admin_url)
        mig_url = apply_migrations(admin_url)
        problems = compare(snapshot(ref_url), snapshot(mig_url))
    finally:
        for name in TEMP_DBS:
            drop(admin_url, name)
    print(
        "RESULTADO:",
        "sin diferencias" if problems == 0 else f"{problems} diferencia(s)",
    )
    return 0 if problems == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
