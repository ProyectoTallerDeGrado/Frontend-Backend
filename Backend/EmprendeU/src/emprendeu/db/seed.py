"""Datos de demostración de EmprendeU (CIE-U).

Se ejecuta UNA vez: si la tabla `usuario` ya tiene filas, no hace nada. Los catálogos
(roles, permisos, etapas, retos, insignias, tipos) ya los siembran las migraciones; aquí
solo van personas y actividad coherentes con ellos.

    uv run python -m emprendeu.db.seed

Se niega a correr con ENVIRONMENT=production. Las cuentas y la historia de cada
emprendimiento están documentadas en `database/SEED.md`.

Vive en `db/` (junto a `metadata.py`) porque, como éste, necesita conocer los modelos de
todos los módulos; ningún módulo lo importa.
"""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.core.config import get_settings
from emprendeu.core.security import hash_password
from emprendeu.db.session import get_engine, get_sessionmaker
from emprendeu.modules.ai_assistant.models import AnalisisSentimiento
from emprendeu.modules.alerts.models import Alerta, TipoAlerta
from emprendeu.modules.audit.models import Bitacora
from emprendeu.modules.entrepreneurs.models import (
    Emprendedor,
    EmprendimientoEmprendedor,
    Postulacion,
)
from emprendeu.modules.gamification.models import (
    EmprendedorInsignia,
    EmprendimientoReto,
    Insignia,
    MovimientoXp,
    Reto,
)
from emprendeu.modules.indicators.models import TipoIndicador, ValorIndicador
from emprendeu.modules.mentoring.models import (
    Asignacion,
    Compromiso,
    DisponibilidadMentor,
    PerfilMentor,
    Recomendacion,
    Seguimiento,
    SesionAcompanamiento,
    SesionParticipante,
    Tipo,
)
from emprendeu.modules.training.models import Capacitacion, CapacitacionParticipante
from emprendeu.modules.users.models import Rol, RolUsuario, Usuario
from emprendeu.modules.ventures.models import (
    Emprendimiento,
    EmprendimientoEtapa,
    EmprendimientoNecesidad,
    Etapa,
    Hito,
    Necesidad,
)

PASSWORD = "Demo12345!"
DOMAIN = "emprendeu.bo"

# (rol, nombre completo, email local, teléfono)
STAFF = [
    ("administrador", "Admin EmprendeU", "admin", "70000001"),
    ("coordinador", "Carolina Mendoza Rojas", "coordinador", "70000002"),
    ("asesor", "Rodrigo Vaca Suárez", "asesor", "70000003"),
    ("asesor", "Patricia Hurtado Camacho", "asesora2", "70000004"),
]

# (email local, nombre completo, documento). El primero es la cuenta principal de prueba.
ENTREPRENEURS = [
    ("emprendedor", "Lucía Fernández Arce", "8123456"),
    ("mateo", "Mateo Peña Justiniano", "8234567"),
    ("valeria", "Valeria Chávez Antelo", "8345678"),
    ("diego", "Diego Roca Salvatierra", "8456789"),
    ("camila", "Camila Soliz Egüez", "8567890"),
    ("sebastian", "Sebastián Parada Ribera", "8678901"),
    ("andrea", "Andrea Menacho Vaca", "8789012"),
    ("joaquin", "Joaquín Terceros Lara", "8890123"),
]

# Clave -> (nombre, sector, descripción, integrantes [(email, rol)], nº de retos cumplidos,
# mentor, días desde el último avance (None = sin avances), ritmo de avances).
VENTURES = {
    "cafe": (
        "Café Altiplano",
        "Alimentos",
        "Café de especialidad de productores de los Yungas, tostado en Santa Cruz.",
        [("emprendedor", "fundador"), ("mateo", "cofundador")],
        3,
        "asesor",
        2,
    ),
    "agro": (
        "AgroSensor",
        "Agrotecnología",
        "Sensores de humedad de bajo costo para pequeños agricultores.",
        [("valeria", "fundador")],
        5,
        "asesor",
        5,
    ),
    "moda": (
        "Tejidos Andinos",
        "Moda sostenible",
        "Prendas de alpaca con diseño contemporáneo hechas por artesanas locales.",
        [("diego", "fundador")],
        6,
        "asesora2",
        1,
    ),
    "edu": (
        "Clases a Mano",
        "Educación",
        "Plataforma de tutorías entre universitarios para primeros semestres.",
        [("camila", "fundador")],
        2,
        "asesora2",
        9,
    ),
    "eco": (
        "EcoEnvases",
        "Medio ambiente",
        "Envases compostables a base de bagazo de caña.",
        [("sebastian", "fundador"), ("andrea", "cofundador")],
        1,
        "asesor",
        26,
    ),
    "app": (
        "Delivery Barrio",
        "Tecnología",
        "App de pedidos para tiendas de barrio.",
        [("joaquin", "fundador")],
        0,
        "asesor",
        None,
    ),
}

# Hitos por emprendimiento: (título, estado, días desde hoy: negativo = pasado)
MILESTONES = {
    "cafe": [
        ("Registro de marca", "cumplido", -40),
        ("Primer lote tostado", "cumplido", -20),
        ("Acuerdo con 3 cafeterías", "pendiente", 15),
    ],
    "agro": [
        ("Prototipo funcional del sensor", "cumplido", -35),
        ("Prueba piloto con 5 agricultores", "cumplido", -10),
        ("Certificación de calidad", "pendiente", 30),
    ],
    "moda": [
        ("Colección cápsula", "cumplido", -60),
        ("Tienda en línea activa", "cumplido", -25),
        ("Primera exportación", "pendiente", 45),
    ],
    "edu": [("Piloto con 20 estudiantes", "pendiente", 12)],
    "eco": [("Fórmula del envase validada", "pendiente", -3)],
}

NEEDS = [
    ("Financiamiento", "Capital para producción o expansión."),
    ("Validación de mercado", "Confirmar que existen clientes dispuestos a pagar."),
    ("Asesoría legal", "Registro de marca, contratos y formalización."),
    ("Desarrollo tecnológico", "Apoyo técnico para construir o mejorar el producto."),
    ("Marketing digital", "Presencia en redes y captación de clientes."),
]
VENTURE_NEEDS = {
    "cafe": [("Marketing digital", "media"), ("Financiamiento", "alta")],
    "agro": [("Desarrollo tecnológico", "alta")],
    "moda": [("Financiamiento", "media")],
    "edu": [("Validación de mercado", "alta")],
    "eco": [("Asesoría legal", "media"), ("Validación de mercado", "alta")],
    "app": [("Desarrollo tecnológico", "media")],
}

# Ventas mensuales (Bs), clientes activos, empleos generados por periodo.
INDICATORS = {
    "cafe": [(2400, 12, 2), (3100, 18, 2), (3900, 25, 3)],
    "agro": [(0, 5, 1), (800, 9, 1), (1500, 14, 2)],
    "moda": [(5200, 40, 5), (6100, 46, 5), (7400, 58, 6)],
}
PERIODS = ["2026-08", "2026-09", "2026-10"]


def _ts(days: float, hour: int = 10) -> datetime:
    base = datetime.now(UTC).replace(hour=hour, minute=0, second=0, microsecond=0)
    return base + timedelta(days=days)


def _split(full: str) -> tuple[str, str]:
    first, _, rest = full.partition(" ")
    return first, rest


async def _already_seeded(session: AsyncSession) -> bool:
    return (
        await session.execute(select(func.count(Usuario.usuario_id)))
    ).scalar_one() > 0


async def seed(session: AsyncSession) -> bool:
    """Siembra los datos de demostración. Devuelve False si la base ya tenía usuarios."""
    if await _already_seeded(session):
        return False

    pwd = hash_password(PASSWORD)
    roles = {r.nombre: r.rol_id for r in (await session.execute(select(Rol))).scalars()}

    async def make_user(
        rol: str, full: str, local: str, phone: str | None = None
    ) -> Usuario:
        nombre, apellido = _split(full)
        user = Usuario(
            nombre=nombre,
            apellido=apellido,
            email=f"{local}@{DOMAIN}",
            password_hash=pwd,
            telefono=phone,
            estado="habilitada",
            fecha_registro=_ts(-70),
        )
        session.add(user)
        await session.flush()
        session.add(RolUsuario(rol_id=roles[rol], usuario_id=user.usuario_id))
        return user

    # --- personal ---------------------------------------------------------
    staff = {}
    for rol, full, local, phone in STAFF:
        staff[local] = await make_user(rol, full, local, phone)
    admin, coord = staff["admin"], staff["coordinador"]
    mentors = {"asesor": staff["asesor"], "asesora2": staff["asesora2"]}

    specialties = {
        "asesor": (
            "Validación de negocio y finanzas",
            "Ingeniero comercial con 8 años acompañando startups en Santa Cruz.",
        ),
        "asesora2": (
            "Marketing y ventas",
            "Especialista en marca y canales digitales para emprendimientos de consumo.",
        ),
    }
    for key, mentor in mentors.items():
        spec, bio = specialties[key]
        session.add(
            PerfilMentor(
                usuario_id=mentor.usuario_id,
                especialidad=spec,
                biografia=bio,
                habilitado=True,
                fecha_habilitacion=_ts(-65),
            )
        )

    # --- emprendedores ----------------------------------------------------
    users: dict[str, Usuario] = {}
    entrepreneurs: dict[str, Emprendedor] = {}
    for local, full, doc in ENTREPRENEURS:
        users[local] = await make_user("emprendedor", full, local)
        ent = Emprendedor(
            usuario_id=users[local].usuario_id,
            documento_identidad=doc,
            estado="activo",
            fecha_registro=_ts(-68),
        )
        session.add(ent)
        entrepreneurs[local] = ent
    await session.flush()

    # --- catálogos sembrados por las migraciones --------------------------
    stages = list(
        (await session.execute(select(Etapa).order_by(Etapa.orden))).scalars()
    )
    retos = list((await session.execute(select(Reto).order_by(Reto.orden))).scalars())
    badges = {b.nombre: b for b in (await session.execute(select(Insignia))).scalars()}
    session_type = (
        await session.execute(select(Tipo).where(Tipo.nombre == "Mentoría"))
    ).scalar_one()
    alert_types = {
        t.nombre: t for t in (await session.execute(select(TipoAlerta))).scalars()
    }
    indicator_types = list(
        (
            await session.execute(
                select(TipoIndicador).order_by(TipoIndicador.tipo_indicador_id)
            )
        ).scalars()
    )
    stage_of_reto = {r.reto_id: r.etapa_id for r in retos}
    stage_index = {s.etapa_id: i for i, s in enumerate(stages)}

    needs = {}
    for name, desc in NEEDS:
        n = Necesidad(nombre=name, descripcion=desc)
        session.add(n)
        needs[name] = n

    # --- emprendimientos, equipo, etapas, camino y XP ---------------------
    ventures: dict[str, Emprendimiento] = {}
    for key, (
        name,
        sector,
        desc,
        team,
        done,
        mentor_key,
        _last_days,
    ) in VENTURES.items():
        started = _ts(-62)
        v = Emprendimiento(
            nombre=name,
            sector=sector,
            descripcion=desc,
            estado="activo",
            fecha_inicio=started,
            fecha_creacion=started,
        )
        session.add(v)
        await session.flush()
        ventures[key] = v
        for local, rol in team:
            session.add(
                EmprendimientoEmprendedor(
                    emprendedor_id=entrepreneurs[local].emprendedor_id,
                    emprendimiento_id=v.emprendimiento_id,
                    rol_en_emprendimiento=rol,
                    fecha_ingreso=started,
                )
            )

        # Etapa actual según los retos cumplidos: el primer reto pendiente marca la etapa.
        current = (
            stages[stage_index[stage_of_reto[retos[done].reto_id]]]
            if done < len(retos)
            else stages[stage_index[retos[-1].etapa_id]]
        )
        step = 62 / (stage_index[current.etapa_id] + 1)
        for i, stage in enumerate(stages[: stage_index[current.etapa_id] + 1]):
            is_current = stage.etapa_id == current.etapa_id
            begin = started + timedelta(days=step * i)
            session.add(
                EmprendimientoEtapa(
                    emprendimiento_id=v.emprendimiento_id,
                    etapa_id=stage.etapa_id,
                    estado="activa" if is_current else "completada",
                    fecha_inicio=begin,
                    fecha_fin=None if is_current else begin + timedelta(days=step),
                )
            )

        # Camino: el fundador cumple los retos en orden, con su XP y sus insignias.
        founder = entrepreneurs[team[0][0]]
        earned: list[str] = []
        for i, reto in enumerate(retos[:done]):
            when = started + timedelta(days=4 + i * (50 / max(done, 1)))
            session.add(
                EmprendimientoReto(
                    emprendimiento_id=v.emprendimiento_id,
                    reto_id=reto.reto_id,
                    estado="completado",
                    fecha_asignacion=when - timedelta(days=3),
                    fecha_completado=when,
                )
            )
            session.add(
                MovimientoXp(
                    emprendedor_id=founder.emprendedor_id,
                    reto_id=reto.reto_id,
                    cantidad=reto.xp_recompensa or 0,
                    motivo=f"Reto: {reto.titulo}",
                    fecha=when,
                )
            )
            if i == 0:
                earned.append("Primer paso")
            if i == 2:  # entrevistas a clientes
                earned.append("Validador")
            if i == len(retos) - 1:
                earned.append("Graduado")
        if mentor_key and done >= 2:
            earned.append("Conector")
        for badge_name in earned:
            badge = badges[badge_name]
            when = started + timedelta(days=30)
            session.add(
                EmprendedorInsignia(
                    emprendedor_id=founder.emprendedor_id,
                    insignia_id=badge.insignia_id,
                    fecha_obtenida=when,
                )
            )
            if badge.xp_recompensa:
                session.add(
                    MovimientoXp(
                        emprendedor_id=founder.emprendedor_id,
                        cantidad=badge.xp_recompensa,
                        motivo=f"Insignia «{badge.nombre}»",
                        fecha=when,
                    )
                )

        # Hitos, ligados a la etapa actual.
        stage_row = (
            await session.execute(
                select(EmprendimientoEtapa).where(
                    EmprendimientoEtapa.emprendimiento_id == v.emprendimiento_id,
                    EmprendimientoEtapa.estado == "activa",
                )
            )
        ).scalar_one()
        for title, state, offset in MILESTONES.get(key, []):
            session.add(
                Hito(
                    emprendimiento_id=v.emprendimiento_id,
                    emprendimiento_etapa_id=stage_row.emprendimiento_etapa_id,
                    titulo=title,
                    estado=state,
                    fecha_estimada=_ts(offset),
                    fecha_cumplimiento=_ts(offset) if state == "cumplido" else None,
                )
            )
        for need_name, priority in VENTURE_NEEDS.get(key, []):
            session.add(
                EmprendimientoNecesidad(
                    emprendimiento_id=v.emprendimiento_id,
                    necesidad_id=needs[need_name].necesidad_id,
                    prioridad=priority,
                    estado="detectada",
                    fecha_detectada=_ts(-30),
                )
            )
    await session.flush()

    # --- asignaciones de mentores ------------------------------------------
    for key, (*_, mentor_key, _last) in VENTURES.items():
        session.add(
            Asignacion(
                usuario_id=mentors[mentor_key].usuario_id,
                emprendimiento_id=ventures[key].emprendimiento_id,
                tipo_asignacion="mentor",
                estado="activa",
                fecha_inicio=_ts(-60),
            )
        )

    # --- avances semanales (seguimientos) ----------------------------------
    for key, venture in VENTURES.items():
        team, last_days = venture[3], venture[6]
        if last_days is None:
            continue
        owner = users[team[0][0]]
        weeks = 6 if last_days < 7 else 3
        for w in range(weeks):
            session.add(
                Seguimiento(
                    emprendimiento_id=ventures[key].emprendimiento_id,
                    usuario_id=owner.usuario_id,
                    fecha=_ts(-last_days - 7 * (weeks - 1 - w)),
                    porcentaje_avance=Decimal(min(100, 15 + 14 * (w + 1))),
                    observaciones=[
                        "Cerramos la lista de proveedores y definimos precios.",
                        "Hicimos 6 entrevistas más y ajustamos la propuesta de valor.",
                        "Primeras ventas de prueba; anotamos objeciones frecuentes.",
                        "Mejoramos el empaque con la retroalimentación del mentor.",
                        "Armamos el calendario de publicaciones del mes.",
                        "Preparamos los números para el plan financiero.",
                    ][w % 6],
                    estado="registrado",
                )
            )

    # --- sesiones de mentoría ----------------------------------------------
    def add_session(
        key: str,
        mentor_key: str,
        offset_days: float,
        state: str,
        topic: str,
        notes: str | None,
    ) -> SesionAcompanamiento:
        when = _ts(offset_days, 15)
        sesion = SesionAcompanamiento(
            emprendimiento_id=ventures[key].emprendimiento_id,
            tipo_id=session_type.tipo_id,
            estado=state,
            fecha_programada=when,
            fecha_realizada=when if state == "realizada" else None,
            modalidad="presencial" if offset_days % 2 else "virtual",
            tema=topic,
            observaciones=notes,
        )
        session.add(sesion)
        return sesion

    plan = [
        (
            "cafe",
            "asesor",
            -28,
            "realizada",
            "Validación de precio",
            "Se acordó probar 3 precios.",
        ),
        (
            "cafe",
            "asesor",
            -9,
            "realizada",
            "Canales de venta",
            "Priorizar cafeterías de la zona.",
        ),
        ("cafe", "asesor", 4, "programada", "Plan financiero", None),
        (
            "agro",
            "asesor",
            -15,
            "realizada",
            "Piloto con agricultores",
            "Medir ahorro de agua.",
        ),
        ("agro", "asesor", 6, "programada", "Costos de producción", None),
        (
            "moda",
            "asesora2",
            -20,
            "realizada",
            "Marca y exportación",
            "Definir mercado inicial.",
        ),
        ("moda", "asesora2", 3, "programada", "Estrategia de redes", None),
        (
            "edu",
            "asesora2",
            -12,
            "realizada",
            "Propuesta de valor",
            "Enfocar a primer semestre.",
        ),
        (
            "eco",
            "asesor",
            -35,
            "realizada",
            "Validación técnica",
            "Pendiente prueba de resistencia.",
        ),
    ]
    sessions = []
    for key, mentor_key, offset, state, topic, notes in plan:
        sesion = add_session(key, mentor_key, offset, state, topic, notes)
        sessions.append((sesion, key, mentor_key))
    await session.flush()
    for sesion, key, mentor_key in sessions:
        owner = users[VENTURES[key][3][0][0]]
        session.add(
            SesionParticipante(
                sesion_acompanamiento_id=sesion.sesion_acompanamiento_id,
                usuario_id=mentors[mentor_key].usuario_id,
                rol_participante="mentor",
            )
        )
        session.add(
            SesionParticipante(
                sesion_acompanamiento_id=sesion.sesion_acompanamiento_id,
                usuario_id=owner.usuario_id,
                rol_participante="emprendedor",
            )
        )

    # Disponibilidad: las sesiones programadas ocupan su hora; hay bloques libres próximos.
    for sesion, _key, mentor_key in sessions:
        if sesion.estado == "programada":
            session.add(
                DisponibilidadMentor(
                    usuario_id=mentors[mentor_key].usuario_id,
                    fecha_inicio=sesion.fecha_programada,
                    fecha_fin=sesion.fecha_programada + timedelta(hours=1),
                    estado="reservado",
                )
            )
    for mentor in mentors.values():
        for day in (8, 9, 10, 11):
            start = _ts(day, 13)  # 09:00 hora de La Paz
            session.add(
                DisponibilidadMentor(
                    usuario_id=mentor.usuario_id,
                    fecha_inicio=start,
                    fecha_fin=start + timedelta(hours=3),
                    estado="disponible",
                )
            )

    # Recomendaciones y compromisos de las sesiones realizadas.
    for sesion, key, mentor_key in sessions:
        if sesion.estado != "realizada":
            continue
        v = ventures[key]
        owner = users[VENTURES[key][3][0][0]]
        session.add(
            Recomendacion(
                emprendimiento_id=v.emprendimiento_id,
                usuario_id=mentors[mentor_key].usuario_id,
                sesion_acompanamiento_id=sesion.sesion_acompanamiento_id,
                titulo=f"Siguiente paso: {sesion.tema}",
                contenido=sesion.observaciones or "Seguir el plan acordado.",
                estado="activa",
                fecha=sesion.fecha_realizada,
            )
        )
        overdue = key == "eco"
        done_it = key in ("moda", "agro")
        session.add(
            Compromiso(
                emprendimiento_id=v.emprendimiento_id,
                sesion_acompanamiento_id=sesion.sesion_acompanamiento_id,
                registrado_por_usuario_id=mentors[mentor_key].usuario_id,
                responsable_usuario_id=owner.usuario_id,
                descripcion=sesion.observaciones
                or "Aplicar lo conversado en la sesión.",
                fecha_limite=sesion.fecha_realizada
                + timedelta(days=7 if overdue else 21),
                estado="completado" if done_it else "pendiente",
                fecha_completado=sesion.fecha_realizada + timedelta(days=5)
                if done_it
                else None,
            )
        )

    # --- alertas coherentes con la actividad -------------------------------
    alert_rows = [
        (
            "eco",
            "inactividad",
            "alta",
            "abierta",
            "EcoEnvases sin avances hace 26 días",
            "No registra avances desde hace más de 14 días.",
        ),
        (
            "eco",
            "compromiso_vencido",
            "media",
            "abierta",
            "Compromiso vencido: prueba de resistencia",
            "El compromiso de la sesión de validación técnica pasó su fecha límite.",
        ),
        (
            "app",
            "inactividad",
            "alta",
            "revisada",
            "Delivery Barrio nunca registró avances",
            "El emprendimiento no tiene avances ni retos cumplidos.",
        ),
        (
            "edu",
            "sentimiento",
            "media",
            "abierta",
            "Caída de ánimo en el Coach IA",
            "El sentimiento promedio bajó en dos semanas consecutivas.",
        ),
    ]
    for key, kind, priority, state, title, desc in alert_rows:
        session.add(
            Alerta(
                emprendimiento_id=ventures[key].emprendimiento_id,
                tipo_alerta_id=alert_types[kind].tipo_alerta_id,
                titulo=title,
                descripcion=desc,
                prioridad=priority,
                estado=state,
                fecha_generacion=_ts(-2),
            )
        )
    # Serie de sentimiento de Camila (baja), Lucía (estable).
    for w, (a, b) in enumerate(
        [(0.55, 0.60), (0.40, 0.62), (0.05, 0.58), (-0.25, 0.64)]
    ):
        for local, idx in (("camila", a), ("emprendedor", b)):
            session.add(
                AnalisisSentimiento(
                    emprendedor_id=entrepreneurs[local].emprendedor_id,
                    indice=Decimal(str(idx)),
                    fecha=_ts(-28 + 7 * w),
                )
            )

    # --- indicadores ---------------------------------------------------------
    for key, rows in INDICATORS.items():
        for period, values in zip(PERIODS, rows, strict=True):
            for tipo, value in zip(indicator_types, values, strict=False):
                session.add(
                    ValorIndicador(
                        emprendimiento_id=ventures[key].emprendimiento_id,
                        tipo_indicador_id=tipo.tipo_indicador_id,
                        periodo=period,
                        valor=Decimal(value),
                        fecha_registro=_ts(
                            -30 * (len(PERIODS) - PERIODS.index(period) - 1)
                        ),
                    )
                )

    # --- capacitaciones --------------------------------------------------------
    trainings = [
        (
            "Modelo de negocio Canvas",
            "taller",
            "presencial",
            "realizada",
            -45,
            ["emprendedor", "mateo", "valeria", "diego", "camila"],
        ),
        (
            "Finanzas para emprendedores",
            "taller",
            "virtual",
            "realizada",
            -18,
            ["emprendedor", "valeria", "diego", "sebastian"],
        ),
        (
            "Pitch de inversión",
            "charla",
            "presencial",
            "programada",
            10,
            ["emprendedor", "diego", "valeria"],
        ),
    ]
    for title, kind, mode, state, offset, attendees in trainings:
        cap = Capacitacion(
            titulo=title,
            descripcion=f"{title}: sesión práctica organizada por el CIE-U.",
            tipo=kind,
            modalidad=mode,
            estado=state,
            fecha=_ts(offset),
        )
        session.add(cap)
        await session.flush()
        for j, local in enumerate(attendees):
            session.add(
                CapacitacionParticipante(
                    capacitacion_id=cap.capacitacion_id,
                    emprendedor_id=entrepreneurs[local].emprendedor_id,
                    asistencia=(j != 3) if state == "realizada" else None,
                    fecha_registro=_ts(offset - 5),
                )
            )

    # --- postulaciones -----------------------------------------------------------
    session.add(
        Postulacion(
            nombre="Rocío",
            apellido="Barba Mamani",
            email=f"rocio@{DOMAIN}",
            telefono="70000010",
            documento_identidad="9012345",
            nombre_emprendimiento="Huerto Vertical",
            descripcion_emprendimiento="Cultivos hidropónicos en espacios urbanos reducidos.",
            sector="Agrotecnología",
            fecha_postulacion=_ts(-3),
            estado="pendiente",
        )
    )
    session.add(
        Postulacion(
            nombre="Bruno",
            apellido="Ibáñez Cuéllar",
            email=f"bruno@{DOMAIN}",
            telefono="70000011",
            documento_identidad="9123456",
            nombre_emprendimiento="Fix Rápido",
            descripcion_emprendimiento="Reparación de celulares a domicilio.",
            sector="Servicios",
            fecha_postulacion=_ts(-1),
            estado="pendiente",
        )
    )
    session.add(
        Postulacion(
            nombre="Elena",
            apellido="Vargas Roca",
            email=f"elena@{DOMAIN}",
            documento_identidad="9234567",
            nombre_emprendimiento="Joyas Express",
            descripcion_emprendimiento="Bisutería importada.",
            sector="Comercio",
            fecha_postulacion=_ts(-20),
            estado="rechazada",
            fecha_decision=_ts(-15),
            decidido_por_usuario_id=coord.usuario_id,
            observaciones_decision="No es una propuesta propia; se sugiere replantear el modelo.",
        )
    )
    await session.flush()
    session.add(
        Postulacion(
            nombre="Lucía",
            apellido="Fernández Arce",
            email=f"emprendedor@{DOMAIN}",
            documento_identidad="8123456",
            nombre_emprendimiento="Café Altiplano",
            descripcion_emprendimiento=VENTURES["cafe"][2],
            sector="Alimentos",
            fecha_postulacion=_ts(-66),
            estado="admitida",
            fecha_decision=_ts(-63),
            decidido_por_usuario_id=coord.usuario_id,
            observaciones_decision="Propuesta con mercado claro.",
            emprendedor_id=entrepreneurs["emprendedor"].emprendedor_id,
            emprendimiento_id=ventures["cafe"].emprendimiento_id,
        )
    )

    # --- bitácora: altas de cuenta ---------------------------------------------------
    for u in list(staff.values()) + list(users.values()):
        session.add(
            Bitacora(
                usuario_id=admin.usuario_id,
                accion="usuarios.crear",
                tabla="usuario",
                id_registro=str(u.usuario_id),
                datos_nuevos={
                    "objeto": f"{u.nombre} {u.apellido}",
                    "resultado": "exitoso",
                    "origen": "seed",
                },
                fecha=_ts(-70),
            )
        )

    await session.commit()
    return True


def _print_accounts() -> None:
    print(
        f"\nDatos de demostración creados. Contraseña de TODAS las cuentas: {PASSWORD}\n"
    )
    for rol, full, local, _ in STAFF:
        print(f"  {rol:<12} {local}@{DOMAIN:<16} {full}")
    for local, full, _ in ENTREPRENEURS:
        print(f"  {'emprendedor':<12} {local}@{DOMAIN:<16} {full}")


async def run() -> int:
    if get_settings().is_production:
        print("Se niega a sembrar datos de demostración con ENVIRONMENT=production.")
        return 2
    try:
        async with get_sessionmaker()() as session:
            created = await seed(session)
    finally:
        await get_engine().dispose()
    if created:
        _print_accounts()
    else:
        print("La base ya tiene usuarios: no se siembra nada.")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(run()))
