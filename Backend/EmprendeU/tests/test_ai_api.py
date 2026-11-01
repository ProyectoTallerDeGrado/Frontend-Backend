"""Coach IA: conocimiento, chat con y sin fuente, sentimiento."""

from httpx import AsyncClient

from tests.conftest import MakeUser

API = "/api/v1"

DOC = (
    "Para calcular tus costos separa costos fijos y variables.\n\n"
    "Con los costos puedes estimar el punto de equilibrio de tus ventas."
)


async def _world(client: AsyncClient, make_user: MakeUser, login):
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(rol="coordinador", email="coord@test.com")
    emp_user = await make_user(email="e@test.com")
    h = {k: await login(f"{k}@test.com") for k in ("admin", "coord", "e")}
    await client.post(f"{API}/ventures", json={"nombre": "Mi idea"}, headers=h["e"])
    return h, emp_user


async def test_conocimiento_exige_permiso_y_se_indexa(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    body = {"titulo": "Guia de costos", "contenido": DOC, "fuente": "CIE-U"}
    assert (
        await client.post(f"{API}/ai/knowledge", json=body, headers=h["e"])
    ).status_code == 403
    created = await client.post(f"{API}/ai/knowledge", json=body, headers=h["admin"])
    assert created.status_code == 201 and created.json()["total_fragmentos"] >= 1
    listing = (await client.get(f"{API}/ai/knowledge", headers=h["admin"])).json()
    assert listing[0]["titulo"] == "Guia de costos"
    status = (await client.get(f"{API}/ai/status", headers=h["admin"])).json()
    assert status == {"ollama_disponible": True, "documentos_activos": 1}
    empty = await client.post(
        f"{API}/ai/knowledge",
        json={"titulo": "x", "contenido": "   "},
        headers=h["admin"],
    )
    assert empty.status_code == 422


async def test_chat_con_fuente_sin_fuente_y_derivacion(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    # sin base documental: respuesta de reserva que deriva a un mentor
    first = await client.post(
        f"{API}/ai/chat", json={"mensaje": "Como calculo mis costos?"}, headers=h["e"]
    )
    assert first.status_code == 200
    body = first.json()
    assert body["fuente"] is False and body["derivar_mentor"] is True
    assert body["respuesta"]["contenido"].startswith(
        "No encontre informacion suficiente"
    )

    await client.post(
        f"{API}/ai/knowledge",
        json={"titulo": "Guia de costos", "contenido": DOC},
        headers=h["admin"],
    )
    cid = body["conversacion_id"]
    sourced = await client.post(
        f"{API}/ai/chat",
        json={"mensaje": "Como calculo mis costos?", "conversacion_id": cid},
        headers=h["e"],
    )
    data = sourced.json()
    assert (
        data["fuente"] is True
        and data["fuentes"] == ["Guia de costos"]
        and data["derivar_mentor"] is False
    )
    assert (
        data["respuesta"]["contenido"] == "Respuesta del coach basada en el contexto."
    )

    # pregunta fuera del conocimiento
    off = (
        await client.post(
            f"{API}/ai/chat",
            json={"mensaje": "Receta de pasta", "conversacion_id": cid},
            headers=h["e"],
        )
    ).json()
    assert off["fuente"] is False and off["derivar_mentor"] is True
    # financiamiento siempre ofrece mentor, aunque haya fuente
    fin = (
        await client.post(
            f"{API}/ai/chat",
            json={"mensaje": "costos y financiamiento", "conversacion_id": cid},
            headers=h["e"],
        )
    ).json()
    assert fin["fuente"] is True and fin["derivar_mentor"] is True

    convs = (await client.get(f"{API}/ai/conversations/me", headers=h["e"])).json()
    assert convs[0]["total_mensajes"] == 8
    msgs = (
        await client.get(f"{API}/ai/conversations/{cid}/messages", headers=h["e"])
    ).json()
    assert [m["tipo"] for m in msgs[:2]] == ["usuario", "asistente"]


async def test_chat_aislamiento_y_ia_caida(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    await make_user(email="otro@test.com")
    other = await login("otro@test.com")
    cid = (
        await client.post(f"{API}/ai/chat", json={"mensaje": "hola"}, headers=h["e"])
    ).json()["conversacion_id"]
    assert (
        await client.get(f"{API}/ai/conversations/{cid}/messages", headers=other)
    ).status_code == 404
    # el personal no es emprendedor: no usa el coach
    denied = await client.post(
        f"{API}/ai/chat", json={"mensaje": "hola"}, headers=h["coord"]
    )
    assert denied.status_code in (403,)

    await client.post(
        f"{API}/ai/knowledge",
        json={"titulo": "G", "contenido": DOC},
        headers=h["admin"],
    )
    client._transport.app.state.fake_llm.down = True  # type: ignore[attr-defined]
    down = await client.post(
        f"{API}/ai/chat", json={"mensaje": "costos"}, headers=h["e"]
    )
    assert down.status_code == 503 and down.json()["error"]["code"] == "ai_unavailable"
    assert (await client.get(f"{API}/ai/status", headers=h["admin"])).json()[
        "ollama_disponible"
    ] is False


async def test_sentimiento_solo_personal(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    await client.post(
        f"{API}/ai/chat",
        json={"mensaje": "Estoy muy triste y cansado, quiero renunciar"},
        headers=h["e"],
    )
    await client.post(
        f"{API}/ai/chat",
        json={"mensaje": "Tuve un gran avance, estoy feliz"},
        headers=h["e"],
    )
    eid = (await client.get(f"{API}/entrepreneurs/me", headers=h["e"])).json()[
        "emprendedor_id"
    ]
    assert (
        await client.get(f"{API}/ai/sentiment/{eid}", headers=h["e"])
    ).status_code == 403
    series = (await client.get(f"{API}/ai/sentiment/{eid}", headers=h["coord"])).json()
    assert len(series) == 1 and series[0]["mensajes"] == 2
    assert -1 <= series[0]["indice_promedio"] <= 1
