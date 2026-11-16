"""CU05: la coordinacion crea un emprendimiento con uno o mas emprendedores y gestiona su equipo."""

from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.ai_assistant import ConversacionIa
from tests.conftest import MakeUser

API = "/api/v1"


async def _entrepreneur(client: AsyncClient, coord: dict, name: str, doc: str) -> int:
    created = await client.post(
        f"{API}/entrepreneurs",
        json={
            "nombre_completo": name,
            "email": f"{doc}@test.com",
            "documento_identidad": doc,
            "password": "clave-segura-123",
        },
        headers=coord,
    )
    assert created.status_code == 201, created.text
    return created.json()["emprendedor_id"]


async def _login_as(client: AsyncClient, doc: str) -> dict[str, str]:
    token = (
        await client.post(
            f"{API}/auth/login",
            json={"email": f"{doc}@test.com", "password": "clave-segura-123"},
        )
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


async def test_cu05_equipo_del_emprendimiento(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="coordinador", email="coord@test.com")
    await make_user(rol="asesor", email="asesor@test.com")
    coord, asesor = await login("coord@test.com"), await login("asesor@test.com")
    rosa = await _entrepreneur(client, coord, "Rosa Quispe", "e111")
    luis = await _entrepreneur(client, coord, "Luis Mamani", "e222")
    ana = await _entrepreneur(client, coord, "Ana Flores", "e333")

    # sin integrantes, repetidos o inexistentes: 422
    empty = await client.post(
        f"{API}/ventures", json={"nombre": "Tejidos", "integrantes": []}, headers=coord
    )
    assert empty.json()["error"]["code"] == "entrepreneur_required"
    dup = await client.post(
        f"{API}/ventures",
        json={
            "nombre": "Tejidos",
            "integrantes": [{"emprendedor_id": rosa}, {"emprendedor_id": rosa}],
        },
        headers=coord,
    )
    assert dup.status_code == 422 and dup.json()["error"]["code"] == "duplicate_member"
    ghost = await client.post(
        f"{API}/ventures",
        json={"nombre": "Tejidos", "integrantes": [{"emprendedor_id": 99999}]},
        headers=coord,
    )
    assert ghost.json()["error"]["code"] == "entrepreneur_not_found"
    bad_role = await client.post(
        f"{API}/ventures",
        json={
            "nombre": "Tejidos",
            "integrantes": [{"emprendedor_id": rosa, "rol_en_emprendimiento": "jefe"}],
        },
        headers=coord,
    )
    assert bad_role.status_code == 422

    # crea con dos integrantes y sus roles
    made = await client.post(
        f"{API}/ventures",
        json={
            "nombre": "Tejidos",
            "integrantes": [
                {"emprendedor_id": rosa, "rol_en_emprendimiento": "fundador"},
                {"emprendedor_id": luis, "rol_en_emprendimiento": "cofundador"},
            ],
        },
        headers=coord,
    )
    assert made.status_code == 201, made.text
    venture = made.json()
    vid = venture["emprendimiento_id"]
    assert [
        (m["emprendedor_id"], m["rol_en_emprendimiento"])
        for m in venture["integrantes"]
    ] == [
        (rosa, "fundador"),
        (luis, "cofundador"),
    ]
    assert venture["integrantes"][0]["nombre"] == "Rosa"

    # ambos lo ven como propio, y ven a su equipo
    rosa_h, luis_h = await _login_as(client, "e111"), await _login_as(client, "e222")
    for headers in (rosa_h, luis_h):
        mine = (await client.get(f"{API}/ventures/me", headers=headers)).json()
        assert [v["emprendimiento_id"] for v in mine] == [vid]
        team = await client.get(f"{API}/ventures/{vid}/members", headers=headers)
        assert team.status_code == 200 and len(team.json()) == 2

    # un emprendedor puede estar en varios emprendimientos
    other = await client.post(
        f"{API}/ventures",
        json={"nombre": "Cafe", "integrantes": [{"emprendedor_id": rosa}]},
        headers=coord,
    )
    assert other.status_code == 201
    mine = (await client.get(f"{API}/ventures/me", headers=rosa_h)).json()
    assert len(mine) == 2

    # agregar: solo la coordinacion; sin duplicar
    add = await client.post(
        f"{API}/ventures/{vid}/members",
        json={"emprendedor_id": ana, "rol_en_emprendimiento": "miembro"},
        headers=coord,
    )
    assert add.status_code == 201 and [m["emprendedor_id"] for m in add.json()] == [
        rosa,
        luis,
        ana,
    ]
    again = await client.post(
        f"{API}/ventures/{vid}/members", json={"emprendedor_id": ana}, headers=coord
    )
    assert (
        again.status_code == 409 and again.json()["error"]["code"] == "already_member"
    )
    for headers in (asesor, rosa_h):
        denied = await client.post(
            f"{API}/ventures/{vid}/members",
            json={"emprendedor_id": ana},
            headers=headers,
        )
        assert denied.status_code == 403
    assert (
        await client.delete(f"{API}/ventures/{vid}/members/{luis}", headers=rosa_h)
    ).status_code == 403

    # cambiar el rol de un integrante: solo la coordinacion, con 404 si no es del equipo
    changed = await client.patch(
        f"{API}/ventures/{vid}/members/{luis}",
        json={"rol_en_emprendimiento": "miembro"},
        headers=coord,
    )
    assert changed.status_code == 200
    assert {m["emprendedor_id"]: m["rol_en_emprendimiento"] for m in changed.json()}[
        luis
    ] == "miembro"
    assert (
        await client.patch(
            f"{API}/ventures/{vid}/members/{luis}",
            json={"rol_en_emprendimiento": "fundador"},
            headers=rosa_h,
        )
    ).status_code == 403
    assert (
        await client.patch(
            f"{API}/ventures/{vid}/members/999999",
            json={"rol_en_emprendimiento": "miembro"},
            headers=coord,
        )
    ).status_code == 404
    assert (
        await client.patch(
            f"{API}/ventures/{vid}/members/{luis}",
            json={"rol_en_emprendimiento": "jefe"},
            headers=coord,
        )
    ).status_code == 422

    # quitar: el que sale deja de verlo; nunca queda vacio
    removed = await client.delete(f"{API}/ventures/{vid}/members/{luis}", headers=coord)
    assert removed.status_code == 200 and luis not in [
        m["emprendedor_id"] for m in removed.json()
    ]
    assert (
        await client.get(f"{API}/ventures/{vid}", headers=luis_h)
    ).status_code == 403
    missing = await client.delete(f"{API}/ventures/{vid}/members/{luis}", headers=coord)
    assert missing.status_code == 404
    await client.delete(f"{API}/ventures/{vid}/members/{ana}", headers=coord)
    last = await client.delete(f"{API}/ventures/{vid}/members/{rosa}", headers=coord)
    assert last.status_code == 409 and last.json()["error"]["code"] == "last_member"

    # la lista del personal trae el equipo
    page = (await client.get(f"{API}/ventures?q=Tejidos", headers=coord)).json()
    assert [m["emprendedor_id"] for m in page["items"][0]["integrantes"]] == [rosa]


async def test_cu05_un_emprendedor_en_varios_emprendimientos(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    await make_user(rol="coordinador", email="coord@test.com")
    coord = await login("coord@test.com")
    rosa = await _entrepreneur(client, coord, "Rosa Quispe", "e111")
    luis = await _entrepreneur(client, coord, "Luis Mamani", "e222")

    async def venture(name: str, owner: int) -> int:
        made = await client.post(
            f"{API}/ventures",
            json={"nombre": name, "integrantes": [{"emprendedor_id": owner}]},
            headers=coord,
        )
        return made.json()["emprendimiento_id"]

    first, second = await venture("Tejidos", rosa), await venture("Cafe", rosa)
    foreign = await venture("Ajeno", luis)
    rosa_h = await _login_as(client, "e111")

    # el Camino se pide por emprendimiento; uno ajeno se rechaza
    for vid in (first, second):
        journey = await client.get(
            f"{API}/journey", params={"emprendimiento_id": vid}, headers=rosa_h
        )
        assert journey.status_code == 200, journey.text
    assert (
        await client.get(
            f"{API}/journey", params={"emprendimiento_id": foreign}, headers=rosa_h
        )
    ).status_code == 403

    # una conversacion nueva con el coach queda en el emprendimiento elegido
    chat = await client.post(
        f"{API}/ai/chat",
        json={"mensaje": "Como calculo mis costos?", "emprendimiento_id": second},
        headers=rosa_h,
    )
    assert chat.status_code == 200, chat.text
    conversation = (
        await session.execute(
            select(ConversacionIa).where(
                ConversacionIa.conversacion_ia_id == chat.json()["conversacion_id"]
            )
        )
    ).scalar_one()
    assert conversation.emprendimiento_id == second
    denied = await client.post(
        f"{API}/ai/chat",
        json={"mensaje": "Hola", "emprendimiento_id": foreign},
        headers=rosa_h,
    )
    assert denied.status_code == 403
