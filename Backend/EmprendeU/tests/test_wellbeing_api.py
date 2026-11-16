"""Bienestar: analisis de animo del coach, coach local, permisos, alerta e informe."""

from datetime import UTC, datetime

from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.ai_assistant import AnalisisSentimiento, AssistantService
from emprendeu.modules.ai_assistant.sentiment import (
    EMOTIONS,
    TOPICS,
    analyze_lexical,
    parse_model_reply,
)
from tests.conftest import MakeUser
from tests.fakes import FakeMailer

API = "/api/v1"
RISK = "Ya no puedo mas, quiero dejarlo todo, las deudas me tienen agotado"


async def _world(client: AsyncClient, make_user: MakeUser, login):
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(rol="coordinador", email="coord@test.com")
    mentor = await make_user(rol="asesor", email="asesor@test.com")
    await make_user(email="e@test.com", nombre="Eva")
    await make_user(email="otro@test.com", nombre="Omar")
    h = {
        k: await login(f"{k}@test.com")
        for k in ("admin", "coord", "asesor", "e", "otro")
    }
    ids = {}
    for key, name in (("e", "Idea de Eva"), ("otro", "Idea de Omar")):
        venture = await client.post(
            f"{API}/ventures", json={"nombre": name}, headers=h[key]
        )
        me = await client.get(f"{API}/entrepreneurs/me", headers=h[key])
        ids[key] = (venture.json()["emprendimiento_id"], me.json()["emprendedor_id"])
    return h, ids, mentor.usuario_id


def _fake(client: AsyncClient):
    return client._transport.app.state.fake_llm  # type: ignore[attr-defined]


async def _rows(session: AsyncSession, emprendedor_id: int):
    stmt = (
        select(AnalisisSentimiento)
        .where(AnalisisSentimiento.emprendedor_id == emprendedor_id)
        .order_by(AnalisisSentimiento.analisis_sentimiento_id)
    )
    return list((await session.execute(stmt)).scalars().all())


def _item(ref: str, **over) -> dict:
    return {
        "referencia_cliente": ref,
        "fecha": datetime.now(UTC).isoformat(),
        "indice": -0.5,
        "emocion": "estres",
        "tema": "finanzas",
        "riesgo": False,
        **over,
    }


def test_analisis_por_palabras_y_validacion_del_modelo() -> None:
    lexical = analyze_lexical("Estoy muy estresado con las deudas del negocio")
    assert lexical.emocion == "estres" and lexical.tema == "finanzas"
    assert lexical.metodo == "lexico" and not lexical.riesgo and lexical.indice < 0
    assert analyze_lexical("¿Cómo armo un flujo de caja?").emocion == "neutral"

    risky = analyze_lexical(RISK)
    assert risky.riesgo and risky.indice <= -0.8

    ok = parse_model_reply(
        'Claro: {"indice": -0.4, "emocion": "frustracion", "tema": "equipo", '
        '"riesgo": false}',
        "mi socio no ayuda",
    )
    assert ok is not None and (ok.emocion, ok.tema, ok.metodo) == (
        "frustracion",
        "equipo",
        "modelo",
    )
    # Fuera de las listas cerradas, sin JSON o con tipos malos: no se usa.
    for bad in (
        "no es json",
        '{"indice": 0, "emocion": "euforia", "tema": "equipo"}',
        '{"indice": "alto", "emocion": "estres", "tema": "equipo"}',
        '{"indice": 0, "emocion": "estres", "tema": "politica"}',
        "[1, 2]",
    ):
        assert parse_model_reply(bad, "x") is None
    # El indice se acota y el riesgo por frases no se pierde aunque el modelo diga false.
    kept = parse_model_reply(
        '{"indice": 7, "emocion": "neutral", "tema": "otro", "riesgo": false}', RISK
    )
    assert kept is not None and kept.riesgo and kept.indice <= -0.8
    assert set(EMOTIONS) and "otro" in TOPICS


async def test_chat_guarda_clasificacion_sin_texto_y_el_modelo_la_afina(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, ids, _ = await _world(client, make_user, login)
    fake = _fake(client)

    # 1) El modelo responde algo invalido: queda el analisis por palabras.
    sent = await client.post(
        f"{API}/ai/chat",
        json={"mensaje": "Estoy estresado con las deudas"},
        headers=h["e"],
    )
    assert sent.status_code == 200
    (row,) = await _rows(session, ids["e"][1])
    assert (row.emocion, row.tema, row.metodo, row.origen) == (
        "estres",
        "finanzas",
        "lexico",
        "servidor",
    )
    assert row.mensaje_ia_id is None  # RF07: sin enlace al mensaje
    assert fake.classify_calls == 1 and fake.chat_calls == 0

    # 2) El modelo clasifica bien: la fila se actualiza.
    fake.classify_reply = (
        '{"indice": 0.7, "emocion": "motivacion", "tema": "ventas_clientes", '
        '"riesgo": false}'
    )
    await client.post(
        f"{API}/ai/chat", json={"mensaje": "Hoy vendi mucho"}, headers=h["e"]
    )
    second = (await _rows(session, ids["e"][1]))[1]
    await session.refresh(second)
    assert (second.emocion, second.tema, second.metodo) == (
        "motivacion",
        "ventas_clientes",
        "modelo",
    )
    assert float(second.indice) == 0.7

    # 3) Con el modelo caido solo para clasificar, el chat responde igual.
    fake.classify_down = True
    third = await client.post(
        f"{API}/ai/chat", json={"mensaje": "Tengo dudas"}, headers=h["e"]
    )
    assert third.status_code == 200
    assert (await _rows(session, ids["e"][1]))[2].metodo == "lexico"


async def test_riesgo_agrega_apoyo_y_crea_una_sola_alerta(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _, _ = await _world(client, make_user, login)
    reply = await client.post(f"{API}/ai/chat", json={"mensaje": RISK}, headers=h["e"])
    body = reply.json()
    assert body["derivar_mentor"] is True
    assert "momento difícil" in body["respuesta"]["contenido"]

    alerts = (await client.get(f"{API}/alerts", headers=h["coord"])).json()["items"]
    assert [a["titulo"] for a in alerts] == ["Señal de riesgo en el coach"]
    assert alerts[0]["prioridad"] == "alta"
    # La alerta no cita el mensaje.
    assert "deudas" not in alerts[0]["descripcion"]

    # Otro mensaje de riesgo no duplica la alerta abierta.
    await client.post(f"{API}/ai/chat", json={"mensaje": RISK}, headers=h["e"])
    again = (await client.get(f"{API}/alerts", headers=h["coord"])).json()
    assert again["total"] == 1


async def test_coach_local_sincroniza_solo_la_clasificacion(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, ids, _ = await _world(client, make_user, login)
    url = f"{API}/ai/sentiment/sync"
    batch = {"items": [_item("ref-00000001"), _item("ref-00000002", riesgo=True)]}

    first = await client.post(url, json=batch, headers=h["e"])
    assert first.status_code == 200
    assert first.json() == {"registrados": 2, "duplicados": 0}
    # Reenviar el mismo lote no duplica.
    assert (await client.post(url, json=batch, headers=h["e"])).json() == {
        "registrados": 0,
        "duplicados": 2,
    }
    rows = await _rows(session, ids["e"][1])
    assert len(rows) == 2 and {r.origen for r in rows} == {"local"}
    # El riesgo sincronizado tambien avisa al personal.
    assert (await client.get(f"{API}/alerts", headers=h["coord"])).json()["total"] == 1

    # No se acepta texto ni claves fuera de las listas, y el personal no sincroniza.
    with_text = {"items": [_item("ref-00000003", mensaje="texto privado")]}
    assert (await client.post(url, json=with_text, headers=h["e"])).status_code == 422
    bad_key = {"items": [_item("ref-00000004", emocion="euforia")]}
    assert (await client.post(url, json=bad_key, headers=h["e"])).status_code == 422
    assert (await client.post(url, json=batch, headers=h["coord"])).status_code == 403


async def test_bienestar_niveles_permisos_y_alcance_del_asesor(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, ids, mentor_id = await _world(client, make_user, login)
    url = f"{API}/ai/wellbeing"
    sync = f"{API}/ai/sentiment/sync"
    # Eva: tres mensajes malos (rojo). Omar: uno solo (sin datos).
    bad = [_item(f"eva-0000000{i}", indice=-0.6) for i in range(3)]
    await client.post(sync, json={"items": bad}, headers=h["e"])
    await client.post(
        sync,
        json={
            "items": [
                _item(
                    "omar-00000001", indice=0.5, emocion="motivacion", tema="producto"
                )
            ]
        },
        headers=h["otro"],
    )

    # El emprendedor no entra; administracion y coordinacion ven a todos.
    assert (await client.get(url, headers=h["e"])).status_code == 403
    for role in ("admin", "coord"):
        report = (await client.get(url, headers=h[role])).json()
        assert [r["nombre"].split()[0] for r in report["emprendedores"]] == [
            "Eva",
            "Omar",
        ]
    eva, omar = report["emprendedores"]
    assert (eva["nivel"], eva["emocion_principal"], eva["tema_principal"]) == (
        "rojo",
        "estres",
        "finanzas",
    )
    assert eva["mensajes"] == 3 and eva["emprendimientos"] == ["Idea de Eva"]
    assert omar["nivel"] == "sin_datos" and report["minimo_mensajes"] == 3
    assert "mensaje" not in eva and "contenido" not in eva  # nunca hay texto

    # El asesor sin asignaciones no ve a nadie; con la de Eva, solo a Eva.
    assert (await client.get(url, headers=h["asesor"])).json()["emprendedores"] == []
    await client.put(
        f"{API}/mentoring/mentors/{mentor_id}/enabled",
        json={"habilitado": True},
        headers=h["coord"],
    )
    assigned = await client.post(
        f"{API}/mentoring/assignments",
        json={"usuario_id": mentor_id, "emprendimiento_id": ids["e"][0]},
        headers=h["coord"],
    )
    assert assigned.status_code == 201, assigned.text
    mine = (await client.get(url, headers=h["asesor"])).json()["emprendedores"]
    assert [r["emprendedor_id"] for r in mine] == [ids["e"][1]]
    assert (
        await client.get(f"{url}/{ids['otro'][1]}", headers=h["asesor"])
    ).status_code == 403

    # Detalle: distribucion, origen y registro en auditoria.
    detail = await client.get(f"{url}/{ids['e'][1]}", headers=h["asesor"])
    assert detail.status_code == 200
    data = detail.json()
    assert data["emociones"] == [{"clave": "estres", "total": 3}]
    assert data["temas"] == [{"clave": "finanzas", "total": 3}]
    assert data["por_origen"] == [{"clave": "local", "total": 3}]
    assert len(data["semanas"]) == 1 and data["semanas"][0]["mensajes"] == 3
    assert (await client.get(f"{url}/999999", headers=h["coord"])).status_code == 404
    audit = (
        await client.get(f"{API}/audit?categoria=negocio", headers=h["admin"])
    ).json()
    assert any(a["accion"] == "negocio.bienestar" for a in audit["items"])


async def test_informe_semanal_va_a_coordinacion_y_administracion_sin_nombres(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, _, _ = await _world(client, make_user, login)
    items = [_item(f"eva-1000000{i}", indice=-0.6) for i in range(3)]
    await client.post(f"{API}/ai/sentiment/sync", json={"items": items}, headers=h["e"])

    mailer = FakeMailer()
    sent = await AssistantService(session).weekly_report(mailer)
    assert sent == 2
    assert {to for to, _, _ in mailer.sent} == {"admin@test.com", "coord@test.com"}
    body = mailer.sent[0][2]
    assert "Necesitan atencion (rojo): 1" in body and "/wellbeing" in body
    assert "Eva" not in body
