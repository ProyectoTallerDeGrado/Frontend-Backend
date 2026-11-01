"""Indice de sentimiento heuristico (lexico en espanol) en el rango [-1, 1].

Es una senal complementaria y barata, no un diagnostico. Se puede sustituir por
un modelo sin tocar al resto: basta con respetar `score(text) -> float`.
"""

from __future__ import annotations

import re
import unicodedata

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
