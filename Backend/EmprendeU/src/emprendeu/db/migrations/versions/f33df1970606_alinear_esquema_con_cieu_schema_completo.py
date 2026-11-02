"""alinear esquema con cieu_schema_completo

Lleva el esquema al de `database/cieu_schema_completo.sql` (Fase 0 del plan de
finalizacion). Cambios, todos aprobados por el responsable del proyecto:

- Extensiones `vector` (pgvector) y `btree_gist` (en `public`).
- `alertas.tipo` y `sesiones_acompanamiento.tipo` (texto): se eliminan; el tipo
  vive en la FK al catalogo.
- `compromisos`: separa quien registra y quien responde, agrega
  `emprendimientoid` y una FK compuesta que obliga a que la sesion sea del mismo
  emprendimiento; la sesion pasa a ser opcional. Se rellenan las filas
  existentes (el responsable era `usuarioid`; el registrante, el mentor de la
  sesion si lo hay).
- `perfil_mentor`: `biografia`, `habilitado`, `fecha_habilitacion`; la PK pasa a
  `perfilmentorid`. Los perfiles existentes quedan habilitados (antes todos lo
  estaban de hecho). `reto_requeridoid` se conserva.
- `disponibilidad_mentor`: de horario semanal recurrente a intervalos concretos
  sin solapamiento (restriccion de exclusion). Se RECREA la tabla: los horarios
  semanales previos se pierden (la base de desarrollo estaba vacia).
- `parametros_seguimiento`: de una fila con columnas a clave-valor. Se RECREA la
  tabla conservando los valores vigentes; la caida de sentimiento pasa de
  porcentaje entero (25) a umbral decimal negativo (-0.25).
- `documentos.hitoid`: evidencia de hito.
- `fragmentos_documento.embedding`: de JSONB a `vector(768)` NOT NULL con indice
  HNSW. Falla de forma ruidosa si hay fragmentos sin embedding o de otra
  dimension.
- Tabla nueva `postulaciones` (CU26).

Revision ID: f33df1970606
Revises: c4d6e8f0a1b3
Create Date: 2026-11-01 17:40:00.000000

"""

from collections.abc import Sequence
from decimal import Decimal

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "f33df1970606"
down_revision: str | Sequence[str] | None = "c4d6e8f0a1b3"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

S = "cieu"

# Claves de `parametros_seguimiento` (ver `alerts/repository.py`).
_PARAM_DESCRIPTIONS = {
    "dias_inactividad": "Dias sin actividad para generar alerta de inactividad (RF10)",
    "umbral_caida_sentimiento": (
        "Caida del indice de sentimiento que dispara alerta (RF11)"
    ),
    "dias_limite_compromiso": "Dias por defecto para el limite de un compromiso (CU18)",
    "periodos_consecutivos": "Periodos seguidos de caida para alertar sentimiento",
    "notificar_coordinador": "Mostrar las alertas a los coordinadores",
    "notificar_asesor": "Mostrar las alertas a los asesores asignados",
    "alertar_incumplimiento": "Alertar por compromisos vencidos sin cumplir",
}


def upgrade() -> None:
    bind = op.get_bind()

    # --- extensiones --------------------------------------------------------
    op.execute("CREATE EXTENSION IF NOT EXISTS vector SCHEMA public")
    op.execute("CREATE EXTENSION IF NOT EXISTS btree_gist SCHEMA public")

    # --- alertas / sesiones: fuera el texto `tipo` ---------------------------
    op.drop_column("alertas", "tipo", schema=S)
    op.drop_column("sesiones_acompanamiento", "tipo", schema=S)
    op.create_unique_constraint(
        "uq_sesiones_id_emprendimiento",
        "sesiones_acompanamiento",
        ["sesiones_acompanamientoid", "emprendimientoid"],
        schema=S,
    )

    # --- compromisos ---------------------------------------------------------
    op.add_column(
        "compromisos",
        sa.Column("registrado_por_usuarioid", sa.BigInteger(), nullable=True),
        schema=S,
    )
    op.add_column(
        "compromisos",
        sa.Column("responsable_usuarioid", sa.BigInteger(), nullable=True),
        schema=S,
    )
    op.add_column(
        "compromisos",
        sa.Column("emprendimientoid", sa.BigInteger(), nullable=True),
        schema=S,
    )
    op.execute(
        f"""
        UPDATE {S}.compromisos c SET
          responsable_usuarioid = c.usuarioid,
          emprendimientoid = (
            SELECT s.emprendimientoid FROM {S}.sesiones_acompanamiento s
            WHERE s.sesiones_acompanamientoid = c.sesiones_acompanamientoid),
          registrado_por_usuarioid = COALESCE(
            (SELECT sp.usuarioid FROM {S}.sesion_participantes sp
             WHERE sp.sesiones_acompanamientoid = c.sesiones_acompanamientoid
               AND sp.rol_participante = 'mentor' LIMIT 1),
            c.usuarioid)
        """
    )
    op.alter_column("compromisos", "registrado_por_usuarioid", nullable=False, schema=S)
    op.alter_column("compromisos", "responsable_usuarioid", nullable=False, schema=S)
    op.alter_column("compromisos", "emprendimientoid", nullable=False, schema=S)
    op.alter_column("compromisos", "sesiones_acompanamientoid", nullable=True, schema=S)
    op.drop_index("ix_compromisos_usuarioid", table_name="compromisos", schema=S)
    op.drop_column(
        "compromisos", "usuarioid", schema=S
    )  # arrastra fk_compromisos_usuarioid
    op.drop_column("compromisos", "responsable_usuario", schema=S)
    for name, col, target in (
        (
            "fk_compromisos_registrado_por",
            "registrado_por_usuarioid",
            "usuario.usuarioid",
        ),
        ("fk_compromisos_responsable", "responsable_usuarioid", "usuario.usuarioid"),
        (
            "fk_compromisos_emprendimientoid",
            "emprendimientoid",
            "emprendimiento.emprendimientoid",
        ),
    ):
        op.create_foreign_key(
            name,
            "compromisos",
            target.split(".")[0],
            [col],
            [target.split(".")[1]],
            source_schema=S,
            referent_schema=S,
            ondelete="RESTRICT",
        )
    op.create_foreign_key(
        "fk_compromisos_sesion_mismo_emp",
        "compromisos",
        "sesiones_acompanamiento",
        ["sesiones_acompanamientoid", "emprendimientoid"],
        ["sesiones_acompanamientoid", "emprendimientoid"],
        source_schema=S,
        referent_schema=S,
        ondelete="RESTRICT",
    )
    op.create_index(
        "ix_compromisos_registrado_por",
        "compromisos",
        ["registrado_por_usuarioid"],
        schema=S,
    )
    op.create_index(
        "ix_compromisos_responsable", "compromisos", ["responsable_usuarioid"], schema=S
    )
    op.create_index(
        "ix_compromisos_emprendimientoid", "compromisos", ["emprendimientoid"], schema=S
    )

    # --- perfil_mentor --------------------------------------------------------
    op.alter_column(
        "perfil_mentor", "perfil_mentorid", new_column_name="perfilmentorid", schema=S
    )
    op.add_column("perfil_mentor", sa.Column("biografia", sa.Text()), schema=S)
    op.add_column(
        "perfil_mentor",
        sa.Column(
            "habilitado", sa.Boolean(), server_default=sa.text("false"), nullable=False
        ),
        schema=S,
    )
    op.add_column(
        "perfil_mentor",
        sa.Column("fecha_habilitacion", sa.DateTime(timezone=True)),
        schema=S,
    )
    op.execute(
        f"UPDATE {S}.perfil_mentor SET habilitado = true, "
        "fecha_habilitacion = CURRENT_TIMESTAMP"
    )
    op.create_check_constraint(
        "ck_perfil_mentor_habilitacion",
        "perfil_mentor",
        "NOT habilitado OR fecha_habilitacion IS NOT NULL",
        schema=S,
    )

    # --- disponibilidad_mentor: se recrea con intervalos concretos ------------
    op.drop_table("disponibilidad_mentor", schema=S)
    op.create_table(
        "disponibilidad_mentor",
        sa.Column("fecha_inicio", sa.DateTime(timezone=True), nullable=False),
        sa.Column("fecha_fin", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "estado",
            sa.String(40),
            server_default="disponible",
            nullable=False,
        ),
        sa.Column(
            "disponibilidadmentorid",
            sa.BigInteger(),
            sa.Identity(always=False),
            nullable=False,
        ),
        sa.Column("usuarioid", sa.BigInteger(), nullable=False),
        sa.CheckConstraint(
            "estado IN ('disponible', 'bloqueado', 'reservado')",
            name="ck_disponibilidad_mentor_estado",
        ),
        sa.CheckConstraint(
            "fecha_fin > fecha_inicio", name="ck_disponibilidad_mentor_fechas"
        ),
        postgresql.ExcludeConstraint(
            ("usuarioid", "="),
            (sa.text("tstzrange(fecha_inicio, fecha_fin)"), "&&"),
            using="gist",
            name="ex_disponibilidad_mentor_solapamiento",
        ),
        sa.ForeignKeyConstraint(
            ["usuarioid"],
            [f"{S}.usuario.usuarioid"],
            name="fk_disponibilidad_mentor_usuarioid",
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("disponibilidadmentorid"),
        schema=S,
    )

    # --- parametros_seguimiento: de una fila a clave-valor --------------------
    old = (
        bind.execute(
            sa.text(
                "SELECT inactividad_dias, caida_sentimiento_pct, periodos_consecutivos, "
                "notificar_coordinador, notificar_asesor, alertar_incumplimiento, "
                f"fecha_actualizacion, usuarioid FROM {S}.parametros_seguimiento "
                "ORDER BY parametros_seguimientoid LIMIT 1"
            )
        )
        .mappings()
        .first()
    )
    values = {
        "dias_inactividad": str(old["inactividad_dias"]) if old else "14",
        "umbral_caida_sentimiento": (
            f"-{Decimal(old['caida_sentimiento_pct']) / 100:.2f}" if old else "-0.25"
        ),
        "dias_limite_compromiso": "7",
        "periodos_consecutivos": str(old["periodos_consecutivos"]) if old else "2",
        "notificar_coordinador": str(
            old["notificar_coordinador"] if old else True
        ).lower(),
        "notificar_asesor": str(old["notificar_asesor"] if old else True).lower(),
        "alertar_incumplimiento": str(
            old["alertar_incumplimiento"] if old else False
        ).lower(),
    }
    op.drop_table("parametros_seguimiento", schema=S)
    params = op.create_table(
        "parametros_seguimiento",
        sa.Column("clave", sa.String(80), nullable=False),
        sa.Column("valor", sa.String(255), nullable=False),
        sa.Column("descripcion", sa.Text()),
        sa.Column(
            "fecha_actualizacion",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
        sa.Column(
            "parametrosseguimientoid",
            sa.BigInteger(),
            sa.Identity(always=False),
            nullable=False,
        ),
        sa.Column("usuarioid", sa.BigInteger()),
        sa.ForeignKeyConstraint(
            ["usuarioid"],
            [f"{S}.usuario.usuarioid"],
            name="fk_parametros_seguimiento_usuarioid",
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("parametrosseguimientoid"),
        sa.UniqueConstraint("clave", name="uq_parametros_seguimiento_clave"),
        schema=S,
    )
    op.bulk_insert(
        params,
        [
            {
                "clave": key,
                "valor": value,
                "descripcion": _PARAM_DESCRIPTIONS[key],
                "usuarioid": old["usuarioid"] if old else None,
                **(
                    {"fecha_actualizacion": old["fecha_actualizacion"]}
                    if old and old["fecha_actualizacion"]
                    else {}
                ),
            }
            for key, value in values.items()
        ],
    )

    # --- documentos.hitoid -----------------------------------------------------
    op.add_column(
        "documentos", sa.Column("hitoid", sa.BigInteger(), nullable=True), schema=S
    )
    op.create_foreign_key(
        "fk_documentos_hitoid",
        "documentos",
        "hito",
        ["hitoid"],
        ["hitoid"],
        source_schema=S,
        referent_schema=S,
        ondelete="RESTRICT",
    )
    op.create_index("ix_documentos_hitoid", "documentos", ["hitoid"], schema=S)

    # --- embeddings: JSONB {"vector": [...]} -> vector(768) -------------------
    op.execute(
        f"ALTER TABLE {S}.fragmentos_documento ALTER COLUMN embedding "
        "TYPE public.vector(768) USING ((embedding -> 'vector')::text::public.vector(768))"
    )
    op.alter_column("fragmentos_documento", "embedding", nullable=False, schema=S)
    op.create_index(
        "ix_fragmentos_documento_embedding",
        "fragmentos_documento",
        ["embedding"],
        schema=S,
        postgresql_using="hnsw",
        postgresql_ops={"embedding": "vector_cosine_ops"},
    )

    # --- postulaciones (CU26) ---------------------------------------------------
    op.create_table(
        "postulaciones",
        sa.Column("nombre", sa.String(160), nullable=False),
        sa.Column("apellido", sa.String(120), nullable=False),
        sa.Column("email", sa.String(254), nullable=False),
        sa.Column("telefono", sa.String(35)),
        sa.Column("documento_identidad", sa.String(50)),
        sa.Column("nombre_emprendimiento", sa.String(160), nullable=False),
        sa.Column("descripcion_emprendimiento", sa.Text()),
        sa.Column("sector", sa.String(120)),
        sa.Column(
            "fecha_postulacion",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column("estado", sa.String(40), server_default="pendiente", nullable=False),
        sa.Column("fecha_decision", sa.DateTime(timezone=True)),
        sa.Column("observaciones_decision", sa.Text()),
        sa.Column(
            "postulacionesid",
            sa.BigInteger(),
            sa.Identity(always=False),
            nullable=False,
        ),
        sa.Column("decidido_por_usuarioid", sa.BigInteger()),
        sa.Column("emprendedorid", sa.BigInteger()),
        sa.Column("emprendimientoid", sa.BigInteger()),
        sa.CheckConstraint(
            "estado IN ('pendiente', 'admitida', 'rechazada')",
            name="ck_postulaciones_estado",
        ),
        sa.CheckConstraint(
            "(estado = 'pendiente' AND fecha_decision IS NULL "
            "AND decidido_por_usuarioid IS NULL) "
            "OR (estado <> 'pendiente' AND fecha_decision IS NOT NULL "
            "AND decidido_por_usuarioid IS NOT NULL)",
            name="ck_postulaciones_decision",
        ),
        sa.CheckConstraint(
            "(estado = 'admitida' AND emprendedorid IS NOT NULL "
            "AND emprendimientoid IS NOT NULL) "
            "OR (estado <> 'admitida' AND emprendedorid IS NULL "
            "AND emprendimientoid IS NULL)",
            name="ck_postulaciones_vinculos",
        ),
        sa.ForeignKeyConstraint(
            ["decidido_por_usuarioid"],
            [f"{S}.usuario.usuarioid"],
            name="fk_postulaciones_decidido_por",
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["emprendedorid"],
            [f"{S}.emprendedor.emprendedorid"],
            name="fk_postulaciones_emprendedorid",
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["emprendimientoid"],
            [f"{S}.emprendimiento.emprendimientoid"],
            name="fk_postulaciones_emprendimientoid",
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("postulacionesid"),
        sa.UniqueConstraint("emprendedorid", name="uq_postulaciones_emprendedorid"),
        sa.UniqueConstraint(
            "emprendimientoid", name="uq_postulaciones_emprendimientoid"
        ),
        schema=S,
    )
    op.create_index(
        "uq_postulaciones_email_pendiente",
        "postulaciones",
        [sa.text("lower(email)")],
        unique=True,
        schema=S,
        postgresql_where=sa.text("estado = 'pendiente'"),
    )
    op.create_index(
        "ix_postulaciones_decidido_por",
        "postulaciones",
        ["decidido_por_usuarioid"],
        schema=S,
    )


def downgrade() -> None:
    """Vuelve a la estructura anterior. Se pierden los datos que no caben en ella
    (postulaciones, horarios concretos, claves extra, embeddings no JSON)."""
    bind = op.get_bind()

    op.drop_table("postulaciones", schema=S)

    # embeddings: vector -> JSONB {"vector": [...]}
    op.drop_index(
        "ix_fragmentos_documento_embedding", table_name="fragmentos_documento", schema=S
    )
    op.alter_column("fragmentos_documento", "embedding", nullable=True, schema=S)
    op.execute(
        f"ALTER TABLE {S}.fragmentos_documento ALTER COLUMN embedding "
        "TYPE jsonb USING jsonb_build_object('vector', embedding::text::jsonb)"
    )

    op.drop_index("ix_documentos_hitoid", table_name="documentos", schema=S)
    op.drop_constraint(
        "fk_documentos_hitoid", "documentos", schema=S, type_="foreignkey"
    )
    op.drop_column("documentos", "hitoid", schema=S)

    # parametros_seguimiento: clave-valor -> una fila
    rows = {
        r["clave"]: r["valor"]
        for r in bind.execute(
            sa.text(f"SELECT clave, valor FROM {S}.parametros_seguimiento")
        ).mappings()
    }
    op.drop_table("parametros_seguimiento", schema=S)
    old = op.create_table(
        "parametros_seguimiento",
        sa.Column("alertar_incumplimiento", sa.Boolean(), nullable=False),
        sa.Column("caida_sentimiento_pct", sa.Integer(), nullable=False),
        sa.Column("fecha_actualizacion", sa.DateTime(timezone=True)),
        sa.Column("inactividad_dias", sa.Integer(), nullable=False),
        sa.Column("notificar_asesor", sa.Boolean(), nullable=False),
        sa.Column("notificar_coordinador", sa.Boolean(), nullable=False),
        sa.Column("periodos_consecutivos", sa.Integer(), nullable=False),
        sa.Column("parametros_seguimientoid", sa.BigInteger(), nullable=False),
        sa.Column("usuarioid", sa.BigInteger()),
        sa.CheckConstraint(
            "inactividad_dias BETWEEN 1 AND 365", name="ck_param_inactividad"
        ),
        sa.CheckConstraint(
            "caida_sentimiento_pct BETWEEN 1 AND 100", name="ck_param_caida"
        ),
        sa.CheckConstraint(
            "periodos_consecutivos BETWEEN 1 AND 12", name="ck_param_periodos"
        ),
        sa.ForeignKeyConstraint(
            ["usuarioid"],
            [f"{S}.usuario.usuarioid"],
            name="fk_parametros_seguimiento_usuarioid",
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("parametros_seguimientoid"),
        schema=S,
    )
    op.bulk_insert(
        old,
        [
            {
                "parametros_seguimientoid": 1,
                "inactividad_dias": int(rows.get("dias_inactividad", "14")),
                "caida_sentimiento_pct": round(
                    -float(rows.get("umbral_caida_sentimiento", "-0.25")) * 100
                ),
                "periodos_consecutivos": int(rows.get("periodos_consecutivos", "2")),
                "notificar_coordinador": rows.get("notificar_coordinador", "true")
                == "true",
                "notificar_asesor": rows.get("notificar_asesor", "true") == "true",
                "alertar_incumplimiento": rows.get("alertar_incumplimiento", "false")
                == "true",
            }
        ],
    )

    # disponibilidad_mentor: intervalos -> horario semanal (vacio)
    op.drop_table("disponibilidad_mentor", schema=S)
    op.create_table(
        "disponibilidad_mentor",
        sa.Column("dia_semana", sa.Integer(), nullable=False),
        sa.Column("duracion_min", sa.Integer(), nullable=False),
        sa.Column("hora_inicio", sa.Time(), nullable=False),
        sa.Column(
            "disponibilidad_mentorid",
            sa.BigInteger(),
            sa.Identity(always=False),
            nullable=False,
        ),
        sa.Column("usuarioid", sa.BigInteger(), nullable=False),
        sa.CheckConstraint("dia_semana BETWEEN 0 AND 6", name="ck_disponibilidad_dia"),
        sa.CheckConstraint("duracion_min > 0", name="ck_disponibilidad_duracion"),
        sa.ForeignKeyConstraint(
            ["usuarioid"],
            [f"{S}.usuario.usuarioid"],
            name="fk_disponibilidad_mentor_usuarioid",
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("disponibilidad_mentorid"),
        sa.UniqueConstraint(
            "usuarioid",
            "dia_semana",
            "hora_inicio",
            name="uq_disponibilidad_mentor_usuarioid_dia_hora",
        ),
        schema=S,
    )
    op.create_index(
        "ix_disponibilidad_mentor_usuarioid",
        "disponibilidad_mentor",
        ["usuarioid"],
        schema=S,
    )

    # perfil_mentor
    op.drop_constraint(
        "ck_perfil_mentor_habilitacion", "perfil_mentor", schema=S, type_="check"
    )
    op.drop_column("perfil_mentor", "fecha_habilitacion", schema=S)
    op.drop_column("perfil_mentor", "habilitado", schema=S)
    op.drop_column("perfil_mentor", "biografia", schema=S)
    op.alter_column(
        "perfil_mentor", "perfilmentorid", new_column_name="perfil_mentorid", schema=S
    )

    # compromisos
    op.add_column(
        "compromisos", sa.Column("usuarioid", sa.BigInteger(), nullable=True), schema=S
    )
    op.add_column(
        "compromisos",
        sa.Column("responsable_usuario", sa.String(250)),
        schema=S,
    )
    op.execute(
        f"""
        UPDATE {S}.compromisos c SET usuarioid = c.responsable_usuarioid,
          responsable_usuario = (SELECT u.nombre || ' ' || u.apellido
                                 FROM {S}.usuario u
                                 WHERE u.usuarioid = c.responsable_usuarioid)
        """
    )
    # Compromisos sin sesion no caben en el esquema anterior (sesion NOT NULL).
    op.execute(f"DELETE FROM {S}.compromisos WHERE sesiones_acompanamientoid IS NULL")
    op.alter_column("compromisos", "usuarioid", nullable=False, schema=S)
    op.alter_column(
        "compromisos", "sesiones_acompanamientoid", nullable=False, schema=S
    )
    for name in (
        "fk_compromisos_sesion_mismo_emp",
        "fk_compromisos_emprendimientoid",
        "fk_compromisos_responsable",
        "fk_compromisos_registrado_por",
    ):
        op.drop_constraint(name, "compromisos", schema=S, type_="foreignkey")
    for name in (
        "ix_compromisos_emprendimientoid",
        "ix_compromisos_responsable",
        "ix_compromisos_registrado_por",
    ):
        op.drop_index(name, table_name="compromisos", schema=S)
    op.drop_column("compromisos", "emprendimientoid", schema=S)
    op.drop_column("compromisos", "responsable_usuarioid", schema=S)
    op.drop_column("compromisos", "registrado_por_usuarioid", schema=S)
    op.create_foreign_key(
        "fk_compromisos_usuarioid",
        "compromisos",
        "usuario",
        ["usuarioid"],
        ["usuarioid"],
        source_schema=S,
        referent_schema=S,
        ondelete="RESTRICT",
    )
    op.create_index("ix_compromisos_usuarioid", "compromisos", ["usuarioid"], schema=S)

    # tipo (texto) en alertas y sesiones, rellenado desde el catalogo
    op.drop_constraint(
        "uq_sesiones_id_emprendimiento",
        "sesiones_acompanamiento",
        schema=S,
        type_="unique",
    )
    op.add_column("sesiones_acompanamiento", sa.Column("tipo", sa.String(60)), schema=S)
    op.add_column("alertas", sa.Column("tipo", sa.String(60)), schema=S)
    op.execute(
        f"UPDATE {S}.sesiones_acompanamiento s SET tipo = t.nombre "
        f"FROM {S}.tipo t WHERE t.tipoid = s.tipoid"
    )
    op.execute(
        f"UPDATE {S}.alertas a SET tipo = t.nombre "
        f"FROM {S}.tipos t WHERE t.tiposid = a.tiposid"
    )
