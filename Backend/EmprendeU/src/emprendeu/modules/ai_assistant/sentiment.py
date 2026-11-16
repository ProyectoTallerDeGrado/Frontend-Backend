"""Analisis de animo de un mensaje: indice en [-1, 1], emocion, tema y riesgo.

Es una senal complementaria, no un diagnostico. Hay dos metodos con el mismo
resultado (`Analysis`): por palabras (`analyze_lexical`, inmediato) y con el modelo
del coach (`CLASSIFY_PROMPT` + `parse_model_reply`), que lo afina despues de responder.
"""

from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass

POSITIVE = {
    "bien",
    "bueno",
    "buena",
    "genial",
    "excelente",
    "feliz",
    "contento",
    "contenta",
    "logre",
    "logramos",
    "avance",
    "avanzo",
    "gracias",
    "motivado",
    "motivada",
    "exito",
    "listo",
    "mejor",
    "mejora",
    "ganas",
    "fuerte",
    "seguro",
    "segura",
}
NEGATIVE = {
    "mal",
    "malo",
    "mala",
    "triste",
    "cansado",
    "cansada",
    "agotado",
    "agotada",
    "frustrado",
    "frustrada",
    "preocupado",
    "preocupada",
    "estres",
    "estresado",
    "imposible",
    "fracaso",
    "renuncio",
    "renunciar",
    "abandonar",
    "dejar",
    "perdido",
    "perdida",
    "no puedo",
    "sin ganas",
    "deuda",
    "quiebra",
    "miedo",
}


def _normalize(text: str) -> str:
    plain = unicodedata.normalize("NFKD", text.lower())
    return "".join(c for c in plain if not unicodedata.combining(c))


def score(text: str) -> float:
    plain = _normalize(text)
    words = re.findall(r"[a-z]+", plain)
    positive = sum(1 for w in words if w in POSITIVE)
    negative = sum(1 for w in words if w in NEGATIVE)
    negative += sum(1 for phrase in NEGATIVE if " " in phrase and phrase in plain)
    total = positive + negative
    if total == 0:
        return 0.0
    return round((positive - negative) / total, 5)


# --- emocion, tema y riesgo ----------------------------------------------------
#
# Listas cerradas: son las unicas claves que se guardan y que el personal ve. Nunca se
# guarda el texto del mensaje (RF07). El movil tiene las mismas listas en Dart.

EMOTIONS = (
    "motivacion",
    "tranquilidad",
    "neutral",
    "preocupacion",
    "estres",
    "frustracion",
    "desanimo",
)
TOPICS = (
    "finanzas",
    "ventas_clientes",
    "equipo",
    "tiempo_estudios",
    "producto",
    "tramites",
    "personal",
    "otro",
)

# Raices sin tildes: basta con que la palabra empiece asi.
EMOTION_STEMS: dict[str, tuple[str, ...]] = {
    "motivacion": ("motiv", "logr", "emocion", "feliz", "content", "genial", "ganas"),
    "tranquilidad": ("tranquil", "calma", "alivi", "segur", "confi"),
    "preocupacion": ("preocup", "miedo", "duda", "nervios", "insegur", "temo"),
    "estres": ("estres", "agotad", "cansad", "presion", "abrumad", "saturad"),
    "frustracion": ("frustr", "harto", "harta", "molest", "rabia", "imposible"),
    "desanimo": ("triste", "desanim", "desmotiv", "fracas", "rendi", "perdid", "sol"),
}
TOPIC_STEMS: dict[str, tuple[str, ...]] = {
    "finanzas": (
        "dinero", "plata", "deuda", "costo", "precio", "financ", "credito",
        "prestamo", "inversi", "capital", "ganancia", "perdida", "quiebra",
    ),
    "ventas_clientes": ("venta", "vend", "cliente", "mercado", "compr", "pedido"),
    "equipo": ("equipo", "socio", "socia", "companer", "integrante", "cofundador"),
    "tiempo_estudios": (
        "tiempo", "universidad", "clases", "examen", "estudi", "materia", "horario",
    ),
    "producto": ("producto", "prototipo", "servicio", "diseno", "calidad", "proveedor"),
    "tramites": ("tramite", "legal", "contrato", "impuesto", "nit", "licencia", "registro"),
    "personal": ("familia", "salud", "dormir", "ansiedad", "animo", "pareja"),
}  # fmt: skip

# Frases (normalizadas) que piden atencion pronta de una persona.
RISK_PHRASES = (
    "no puedo mas",
    "ya no puedo",
    "dejarlo todo",
    "dejar todo",
    "abandonar todo",
    "abandonarlo todo",
    "tirar la toalla",
    "me rindo",
    "rendirme",
    "no vale la pena",
    "no tiene sentido",
    "ya no quiero seguir",
    "no quiero seguir",
    "no sirvo",
    "hacerme dano",
    "no quiero vivir",
    "suicid",
    "desesperad",
)

# Empate entre emociones: gana la que mas conviene atender.
_EMOTION_PRIORITY = (
    "desanimo",
    "frustracion",
    "estres",
    "preocupacion",
    "motivacion",
    "tranquilidad",
)

CLASSIFY_PROMPT = (
    "Clasificas el estado de animo de un mensaje que un emprendedor universitario "
    "le escribio a su coach. No respondas al mensaje. Devuelve SOLO un objeto JSON, "
    "sin texto antes ni despues, con estas claves:\n"
    '- "indice": numero entre -1 (muy negativo) y 1 (muy positivo); 0 si es neutro '
    "o una pregunta tecnica sin carga emocional.\n"
    f'- "emocion": una de {", ".join(EMOTIONS)}.\n'
    f'- "tema": una de {", ".join(TOPICS)}.\n'
    '- "riesgo": true solo si expresa querer abandonar todo, desesperanza fuerte o '
    "hacerse dano; si no, false.\n"
    'Ejemplo: {"indice": -0.6, "emocion": "estres", "tema": "finanzas", "riesgo": false}'
)


@dataclass(frozen=True, slots=True)
class Analysis:
    """Resultado del analisis de un mensaje. No contiene el texto."""

    indice: float
    emocion: str
    tema: str
    riesgo: bool
    metodo: str  # "lexico" | "modelo"


def _best(words: list[str], stems: dict[str, tuple[str, ...]]) -> dict[str, int]:
    return {
        key: sum(1 for w in words if w.startswith(prefixes))
        for key, prefixes in stems.items()
    }


def has_risk(text: str) -> bool:
    plain = _normalize(text)
    return any(phrase in plain for phrase in RISK_PHRASES)


def analyze_lexical(text: str) -> Analysis:
    """Analisis por palabras: inmediato y sin modelo. Es el respaldo del modelo."""
    plain = _normalize(text)
    words = re.findall(r"[a-z]+", plain)
    indice = score(text)

    hits = _best(words, EMOTION_STEMS)
    top = max(hits.values(), default=0)
    if top > 0:
        emocion = next(e for e in _EMOTION_PRIORITY if hits.get(e) == top)
    elif indice >= 0.3:
        emocion = "motivacion"
    elif indice <= -0.3:
        emocion = "desanimo"
    else:
        emocion = "neutral"

    topics = _best(words, TOPIC_STEMS)
    best_topic = max(topics.values(), default=0)
    tema = (
        next(t for t in TOPICS if topics.get(t) == best_topic)
        if best_topic > 0
        else "otro"
    )

    riesgo = has_risk(text)
    if riesgo:
        indice = min(indice, -0.8)
        if emocion in ("neutral", "motivacion", "tranquilidad"):
            emocion = "desanimo"
    return Analysis(indice, emocion, tema, riesgo, "lexico")


def parse_model_reply(raw: str, text: str) -> Analysis | None:
    """Valida la respuesta del modelo contra las listas cerradas; `None` si no sirve.

    El riesgo por frases clave nunca se pierde: si el modelo no lo vio, se mantiene.
    """
    match = re.search(r"\{.*\}", raw, re.DOTALL)
    if match is None:
        return None
    try:
        data = json.loads(match.group(0))
    except ValueError:
        return None
    if not isinstance(data, dict):
        return None
    indice, emocion, tema = data.get("indice"), data.get("emocion"), data.get("tema")
    if isinstance(indice, bool) or not isinstance(indice, int | float):
        return None
    if emocion not in EMOTIONS or tema not in TOPICS:
        return None
    riesgo = data.get("riesgo") is True or has_risk(text)
    indice = max(-1.0, min(1.0, float(indice)))
    if riesgo:
        indice = min(indice, -0.8)
    return Analysis(round(indice, 5), emocion, tema, riesgo, "modelo")
