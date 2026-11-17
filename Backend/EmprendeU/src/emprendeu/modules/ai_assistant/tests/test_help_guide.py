"""Guia del asistente de ayuda: filtrado por rol y respuestas sin IA."""

import pytest

from emprendeu.modules.ai_assistant.help_guide import (
    faq_answer,
    guide_for,
    topic_for_route,
)


@pytest.mark.parametrize(
    ("question", "role", "title"),
    [
        ("¿Cómo asigno un asesor a un emprendimiento?", "coordinador", "Asignaciones"),
        ("como creo un usuario nuevo", "administrador", "Usuarios"),
        ("donde descargo un reporte en excel", "coordinador", "Reportes"),
        ("como cambio mi contraseña", "asesor", "Mi cuenta"),
        ("como registro una sesion", "asesor", "Sesiones"),
        ("como agrego mi horario", "asesor", "Mi disponibilidad"),
        ("como registro asistencia del taller", "coordinador", "Capacitaciones"),
    ],
)
def test_faq_elige_el_tema_de_la_pregunta(question: str, role: str, title: str) -> None:
    assert faq_answer(question, role, None).startswith(f"**{title}**")


def test_faq_sin_coincidencia_usa_la_pantalla_actual() -> None:
    assert faq_answer("hola", "asesor", "/mentoring/sessions/3").startswith(
        "**Sesiones**"
    )
    assert "No encontré" in faq_answer("hola", "asesor", None)


def test_la_guia_solo_muestra_lo_que_el_rol_ve() -> None:
    asesor = guide_for("asesor")
    assert "Mi disponibilidad" in asesor and "## Usuarios" not in asesor
    admin = guide_for("administrador")
    assert "## Usuarios" in admin and "Mi disponibilidad" not in admin
    # Un asesor no gestiona usuarios: la guia no se lo ofrece aunque pregunte.
    assert not faq_answer("como creo un usuario", "asesor", None).startswith(
        "**Usuarios**"
    )


def test_ruta_mas_especifica() -> None:
    topic = topic_for_route("/mentoring/assignments", "coordinador")
    assert topic is not None and topic.title == "Asignaciones"
