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
    assert created.json()["estado"] == "activo"
    # la coordinacion tambien administra la base (CU31)
    by_coord = await client.post(
        f"{API}/ai/knowledge", json={**body, "titulo": "Otra"}, headers=h["coord"]
    )
    assert by_coord.status_code == 201
    listing = (await client.get(f"{API}/ai/knowledge", headers=h["admin"])).json()
    assert {d["titulo"] for d in listing} == {"Guia de costos", "Otra"}
    status = (await client.get(f"{API}/ai/status", headers=h["admin"])).json()
    assert status == {"ollama_disponible": True, "documentos_activos": 2}
    empty = await client.post(
        f"{API}/ai/knowledge",
        json={"titulo": "x", "contenido": "   "},
        headers=h["admin"],
    )
    assert empty.status_code == 422


async def test_modelo_con_otra_dimension_no_guarda_nada(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)

    async def short(texts: list[str]) -> list[list[float]]:
        return [[1.0, 2.0] for _ in texts]  # la base espera 768 dimensiones

    client._transport.app.state.fake_llm.embed = short  # type: ignore[attr-defined]
    r = await client.post(
        f"{API}/ai/knowledge",
        json={"titulo": "Guia", "contenido": DOC},
        headers=h["admin"],
    )
    assert r.status_code == 503 and r.json()["error"]["code"] == "ai_unavailable"
    assert "768" in r.json()["error"]["message"]
    # el intento queda visible como `error`, sin fragmentos y sin servir al coach
    listing = (await client.get(f"{API}/ai/knowledge", headers=h["admin"])).json()
    assert [(d["estado"], d["total_fragmentos"]) for d in listing] == [("error", 0)]
    status = (await client.get(f"{API}/ai/status", headers=h["admin"])).json()
    assert status["documentos_activos"] == 0


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
        "No encontré información suficiente"
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
    # el modelo recibe los turnos previos de la misma conversacion (CU11)
    fake = client._transport.app.state.fake_llm  # type: ignore[attr-defined]
    assert [role for role, _ in fake.last_history] == ["user", "assistant"]
    assert fake.last_history[0][1] == "Como calculo mis costos?"

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
