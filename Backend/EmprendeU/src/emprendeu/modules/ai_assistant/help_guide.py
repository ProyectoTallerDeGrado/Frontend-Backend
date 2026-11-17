"""Guia de uso del panel web: contexto del asistente de ayuda y respuestas sin IA.

Cada tema describe una pantalla del panel (ruta, para qué sirve y como se usa). Con
Gemini disponible la guía entera (filtrada por rol) va en el prompt; sin el, o con la
cuota agotada, `faq_answer` elige el tema más parecido a la pregunta por palabras.

Si cambia una pantalla o el menú (`Frontend/emprendeu/app/(app)/layout.tsx`), se
actualiza aqui en el mismo cambio.
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass, field

STAFF = frozenset({"administrador", "coordinador", "asesor"})


@dataclass(frozen=True)
class HelpTopic:
    key: str
    title: str
    route: str | None
    summary: str
    steps: tuple[str, ...]
    keywords: tuple[str, ...]
    # Roles que ven la pantalla en el menú; `STAFF` = todo el personal.
    roles: frozenset[str] = field(default=STAFF)


TOPICS: tuple[HelpTopic, ...] = (
    HelpTopic(
        "navegacion",
        "Moverse por el sistema",
        None,
        "El menú de la izquierda agrupa las pantallas por tarea: Inicio, Programa, "
        "Acompañamiento y Configuración. Solo ves lo que tu rol tiene permitido.",
        (
            "En computadora el menú está siempre a la izquierda; en celular se abre con el "
            "botón de menú arriba a la derecha.",
            "Tu tarjeta al pie del menú lleva a Mi cuenta; debajo está Cerrar sesión.",
            "El botón de ayuda (abajo a la derecha) abre este asistente y permite repetir "
            "el tutorial guiado.",
        ),
        (
            "menú",
            "navegar",
            "donde",
            "encontrar",
            "pantalla",
            "inicio",
            "empezar",
            "ayuda",
        ),
    ),
    HelpTopic(
        "resumen",
        "Resumen",
        "/panel",
        "Pantalla de inicio: cifras del programa hoy (emprendimientos, sesiones, alertas) y "
        "la actividad reciente.",
        ("Entra desde Inicio > Resumen o tocando el logo CIE-U.",),
        ("resumen", "panel", "inicio", "hoy", "actividad", "cifras"),
    ),
    HelpTopic(
        "indicadores",
        "Indicadores",
        "/dashboard",
        "Como avanzan los emprendimientos activos: etapas, mentorías, compromisos, alertas e "
        "indicadores.",
        (
            "Usa los filtros de periodo (desde / hasta) y de etapa para acotar los datos.",
        ),
        ("indicador", "dashboard", "graficos", "estadistica", "metricas", "avance"),
    ),
    HelpTopic(
        "reportes",
        "Reportes",
        "/reports",
        "Genera reportes del programa: resumen, sesiones, alertas e indicadores.",
        (
            "Elige el tipo de reporte.",
            "Filtra por periodo y etapa y revisa la vista previa.",
            "Descárgalo en CSV o Excel con el botón de exportar.",
        ),
        ("reporte", "exportar", "descargar", "csv", "excel", "informe"),
    ),
    HelpTopic(
        "admisiones",
        "Admisiones",
        "/admissions",
        "Postulaciones que llegan desde la página pública. Admitir crea la cuenta del "
        "emprendedor y su emprendimiento; admitir o rechazar es definitivo.",
        (
            "Abre una postulación para ver sus datos.",
            "Pulsa Admitir o Rechazar y confirma; se le avisa a la persona.",
        ),
        ("admision", "postulación", "postular", "admitir", "rechazar", "solicitud"),
        frozenset({"administrador", "coordinador"}),
    ),
    HelpTopic(
        "emprendedores",
        "Emprendedores",
        "/entrepreneurs",
        "Personas registradas en el programa. El documento de identidad no puede repetirse.",
        (
            "Busca por nombre, correo o documento.",
            "Pulsa Registrar emprendedor, completa nombre, correo y documento y guarda.",
            "Copia la contraseña temporal que aparece: solo se muestra una vez.",
        ),
        (
            "emprendedor",
            "registrar emprendedor",
            "alta",
            "estudiante",
            "documento identidad",
        ),
    ),
    HelpTopic(
        "emprendimientos",
        "Emprendimientos",
        "/ventures",
        "Etapa y equipo de cada emprendimiento. Al abrir uno ves su progreso, seguimiento, "
        "cambios de etapa, documentos e historial.",
        (
            "Pulsa Nuevo emprendimiento, escribe el nombre, el sector y elige su equipo.",
            "Dentro del emprendimiento, Pasar a... (en la cabecera) lo avanza a la siguiente "
            "etapa; solo se puede ir a la siguiente activa.",
            "La pestaña Documentos permite subir, descargar y eliminar archivos (también la "
            "evidencia de los hitos).",
            "Editar emprendimiento cambia sus datos y su equipo.",
        ),
        (
            "emprendimiento",
            "proyecto",
            "etapa",
            "avanzar",
            "pasar",
            "equipo",
            "documento",
            "archivo",
            "hito",
            "progreso",
            "historial",
        ),
    ),
    HelpTopic(
        "necesidades",
        "Necesidades",
        "/needs",
        "Dificultades que reportan los emprendedores para que el CIE-U las atienda. Las "
        "abiertas aparecen primero.",
        ("Revisa la necesidad y márcala como resuelta cuando se atienda.",),
        ("necesidad", "dificultad", "problema", "resolver", "pedido"),
    ),
    HelpTopic(
        "alertas",
        "Alertas",
        "/alerts",
        "Avisos automáticos de seguimiento (inactividad, compromisos vencidos, riesgo). El "
        "número junto al menú son las alertas abiertas.",
        (
            "Filtra por estado o tipo y abre una alerta para ver el detalle.",
            "Márcala como revisada (sigue pendiente), atendida o descartada (se cierran).",
            "Un asesor solo ve alertas de sus emprendimientos asignados.",
        ),
        (
            "alerta",
            "aviso",
            "riesgo",
            "inactividad",
            "atender",
            "descartar",
            "revisada",
        ),
    ),
    HelpTopic(
        "salud",
        "Salud",
        "/health",
        "Puntaje de salud de cada emprendimiento, del más urgente al que mejor va. Combina "
        "alertas, compromisos vencidos, inactividad, tiempo en la etapa y ánimo en el coach.",
        (
            "Verde 70 o más, ámbar 40 a 69, rojo menos de 40; cada descuento muestra su motivo.",
        ),
        ("salud", "puntaje", "urgente", "semaforo", "riesgo"),
    ),
    HelpTopic(
        "asignaciones",
        "Asignaciones",
        "/mentoring/assignments",
        "Habilita asesores y asígnalos a los emprendimientos que acompañarán.",
        (
            "Pulsa Asignar asesor, elige el emprendimiento y un asesor habilitado y confirma.",
            "Solo un asesor habilitado recibe asignaciones; no se duplica una asignación activa.",
        ),
        ("asignar", "asignación", "asesor", "mentor", "habilitar asesor"),
        frozenset({"administrador", "coordinador"}),
    ),
    HelpTopic(
        "disponibilidad",
        "Mi disponibilidad",
        "/mentoring/availability",
        "Define cuándo puedes atender mentorías; los emprendedores asignados agendan dentro "
        "de estos horarios.",
        (
            "Pulsa Agregar horario, elige día y horas y guarda.",
            "Los horarios no pueden solaparse; el ícono de papelera elimina uno.",
        ),
        ("disponibilidad", "horario", "agenda", "cuando", "turno"),
        frozenset({"asesor"}),
    ),
    HelpTopic(
        "sesiones",
        "Sesiones",
        "/mentoring/sessions",
        "Mentorías agendadas y realizadas, con filtros por estado y periodo.",
        (
            "Pulsa Registrar sesión para cargar una mentoria realizada (fecha, tema, "
            "modalidad, observaciones); la fecha no puede ser futura.",
            "Marcar como realizada cierra una sesión agendada.",
            "Desde el seguimiento del emprendimiento se registran recomendaciones y "
            "compromisos con responsable y fecha límite.",
        ),
        (
            "sesión",
            "mentoria",
            "reunion",
            "registrar sesión",
            "compromiso",
            "recomendación",
            "seguimiento",
        ),
    ),
    HelpTopic(
        "capacitaciones",
        "Capacitaciones",
        "/training",
        "Talleres y charlas del programa.",
        (
            "Pulsa Nueva capacitación y completa título, fecha y modalidad.",
            "Entra a una para agregar participantes y registrar la asistencia.",
        ),
        ("capacitación", "taller", "charla", "curso", "asistencia", "participante"),
    ),
    HelpTopic(
        "usuarios",
        "Usuarios",
        "/users",
        "Cuentas de la plataforma: registrar, cambiar rol, habilitar o deshabilitar.",
        (
            "Pulsa Nuevo usuario, completa nombre, correo y rol; copia la contraseña temporal.",
            "En cada fila puedes cambiar el rol o habilitar/deshabilitar la cuenta.",
            "Filtra por rol o estado o busca por nombre o correo.",
        ),
        (
            "usuario",
            "cuenta",
            "crear usuario",
            "deshabilitar",
            "habilitar",
            "rol de usuario",
        ),
        frozenset({"administrador"}),
    ),
    HelpTopic(
        "roles",
        "Roles y permisos",
        "/roles",
        "Define qué puede consultar, registrar, modificar y administrar cada rol.",
        (
            "Pulsa Nuevo rol para crear uno personalizado.",
            "Abre un rol para marcar sus permisos por modulo y guarda los cambios.",
            "Los roles base (administrador, coordinador, asesor, emprendedor) no se eliminan.",
        ),
        ("rol", "permiso", "acceso", "privilegio"),
        frozenset({"administrador"}),
    ),
    HelpTopic(
        "parametros",
        "Parámetros",
        "/settings/tracking",
        "Reglas que usa el sistema para detectar inactividad y riesgo de deserción (días de "
        "inactividad, días límite de compromiso, caida de ánimo).",
        ("Cambia los valores y pulsa Guardar cambios.",),
        ("parametro", "configuracion", "inactividad", "umbral", "regla", "dias"),
        frozenset({"administrador", "coordinador"}),
    ),
    HelpTopic(
        "catalogos",
        "Catálogos y XP",
        "/catalogs",
        "Etapas del ciclo de vida, retos, recompensas de XP e insignias de la gamificación.",
        ("Revisa o edita etapas, retos e insignias desde sus pestañas.",),
        ("catalogo", "xp", "insignia", "reto", "gamificación", "puntos", "etapas"),
        frozenset({"administrador", "coordinador"}),
    ),
    HelpTopic(
        "conocimiento",
        "Base de conocimiento",
        "/knowledge",
        "Documentos con los que responde el coach IA de los emprendedores. Solo los activos "
        "se usan.",
        (
            "Pulsa Subir documento, elige un archivo txt, md, pdf o docx y Subir y procesar.",
            "Espera a que quede activo; puedes desactivarlo cuando ya no sirva.",
            "Preguntas sin respuesta muestra lo que el coach no supo contestar.",
        ),
        ("conocimiento", "coach", "documento", "subir", "ia", "pdf"),
        frozenset({"administrador", "coordinador"}),
    ),
    HelpTopic(
        "auditoria",
        "Auditoría",
        "/audit",
        "Registro de acciones sensibles realizadas en el sistema.",
        ("Filtra por fecha, usuario o acción y expórtalo en CSV.",),
        ("auditoria", "bitacora", "registro", "quien hizo", "acción", "log"),
        frozenset({"administrador", "coordinador"}),
    ),
    HelpTopic(
        "cuenta",
        "Mi cuenta",
        "/account",
        "Tus datos y el cambio de contraseña.",
        (
            "Abre Mi cuenta desde tu tarjeta al pie del menú.",
            "Escribe tu contraseña actual, la nueva dos veces y guarda; se renueva tu sesión.",
            "Si olvidaste la contraseña, en el inicio de sesión usa Olvidé mi contraseña: "
            "llega un código de 6 dígitos al correo.",
        ),
        ("cuenta", "contraseña", "clave", "password", "perfil", "datos", "olvide"),
    ),
)

ROLE_LABELS = {
    "administrador": "Administrador",
    "coordinador": "Coordinador",
    "asesor": "Asesor",
}


def normalize(text: str) -> str:
    """Minusculas, sin tildes ni signos: para comparar palabras."""
    plain = unicodedata.normalize("NFKD", text.lower())
    plain = "".join(c for c in plain if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9 ]+", " ", plain)


def topics_for(role: str | None) -> list[HelpTopic]:
    return [t for t in TOPICS if role in t.roles]


def topic_for_route(route: str | None, role: str | None) -> HelpTopic | None:
    if not route:
        return None
    best: HelpTopic | None = None
    for topic in topics_for(role):
        if topic.route and (
            route == topic.route or route.startswith(f"{topic.route}/")
        ):
            if best is None or len(topic.route) > len(best.route or ""):
                best = topic
    return best


def render_topic(topic: HelpTopic) -> str:
    where = f" (ruta {topic.route})" if topic.route else ""
    steps = "\n".join(f"- {s}" for s in topic.steps)
    return f"## {topic.title}{where}\n{topic.summary}\n{steps}"


def guide_for(role: str | None) -> str:
    return "\n\n".join(render_topic(t) for t in topics_for(role))


def _same_stem(a: str, b: str) -> bool:
    """`asigno` ~ `asignar`, `sesiones` ~ `sesion`: comparten la raiz (>= 5 letras)."""
    if a == b:
        return True
    n = min(len(a), len(b))
    if n < 4:
        return False
    stem = 5 if n >= 5 else n
    return a[:stem] == b[:stem]


def _word_matches(topic: HelpTopic, word: str) -> bool:
    for keyword in topic.keywords:
        kw = normalize(keyword)
        if " " not in kw and _same_stem(word, kw):
            return True
    return False


def _scores(candidates: list[HelpTopic], text: str) -> list[tuple[HelpTopic, float]]:
    """Cada palabra suma mas cuanto menos temas la comparten (como un IDF simple)."""
    words = [w for w in set(text.split()) if len(w) >= 4]
    totals = {t.key: 0.0 for t in candidates}
    for word in words:
        hits = [t for t in candidates if _word_matches(t, word)]
        for t in hits:
            totals[t.key] += 2 / len(hits)
    for t in candidates:
        for keyword in t.keywords:
            kw = normalize(keyword)
            if " " in kw and kw in text:
                totals[t.key] += 3
        if normalize(t.title) in text:
            totals[t.key] += 1
    return sorted(((t, totals[t.key]) for t in candidates), key=lambda p: -p[1])


def faq_answer(question: str, role: str | None, route: str | None) -> str:
    """Respuesta sin IA: el tema que mejor coincide con la pregunta (o el de la pantalla)."""
    candidates = topics_for(role)
    scored = _scores(candidates, normalize(question))
    current = topic_for_route(route, role)
    if scored and scored[0][1] > 0:
        topic = scored[0][0]
    elif current is not None:
        topic = current
    else:
        names = ", ".join(t.title for t in candidates if t.route)
        return (
            "No encontré una respuesta exacta. Puedo ayudarte con estas pantallas: "
            f"{names}. Prueba preguntando, por ejemplo, como registrar una sesión."
        )
    steps = "\n".join(f"{i}. {s}" for i, s in enumerate(topic.steps, 1))
    where = f" Lo encuentras en el menú, en {topic.title}." if topic.route else ""
    return f"**{topic.title}**: {topic.summary}{where}\n\n{steps}"
