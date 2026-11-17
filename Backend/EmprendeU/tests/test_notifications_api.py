"""Notificaciones: bandeja, dispositivos push y avisos que disparan otros modulos."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta

from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.mentoring.service import MentoringService
from emprendeu.modules.notifications import (
    NotificationService,
    PushDispatcher,
    PushMessage,
    PushResult,
    wait_for_pushes,
)
from tests.conftest import MakeUser
from tests.test_mentoring_api import (
    _enable_booking,
    _future_day,
    _set_availability,
    _world,
)

API = "/api/v1"
TOKEN = "fcm-token-de-prueba-0123456789"


def _push(client: AsyncClient):
    return client._transport.app.state.fake_push  # type: ignore[attr-defined]


async def _me(client: AsyncClient, h: dict[str, str]) -> int:
    return (await client.get(f"{API}/auth/me", headers=h)).json()["usuario_id"]


async def _book(client: AsyncClient, h, vid: int, mentor_id: int) -> int:
    day = _future_day()
    await _enable_booking(client, h, vid)
    await _set_availability(client, h, mentor_id, day)
    slot = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()[0]
    r = await client.post(
        f"{API}/mentoring/sessions",
        json={"mentor_id": mentor_id, "inicio": slot["inicio"]},
        headers=h["e"],
    )
    assert r.status_code == 201, r.text
    return r.json()["sesion_id"]


async def test_dispositivos_registrar_reasignar_y_borrar(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    await make_user(email="a@test.com")
    await make_user(email="b@test.com")
    a, b = await login("a@test.com"), await login("b@test.com")
    url = f"{API}/notifications/devices"

    assert (
        await client.put(url, json={"token": TOKEN, "plataforma": "android"})
    ).status_code == 401
    assert (
        await client.put(url, json={"token": TOKEN, "plataforma": "web"}, headers=a)
    ).status_code == 422
    for h in (a, a, b):  # repetir no duplica; otra cuenta en el mismo celular lo toma
        r = await client.put(
            url, json={"token": TOKEN, "plataforma": "android"}, headers=h
        )
        assert r.status_code == 204

    async def owners() -> list[int]:
        rows = await session.execute(
            text("SELECT usuario_id FROM cieu.dispositivos_push WHERE token = :t"),
            {"t": TOKEN},
        )
        return [r[0] for r in rows]

    assert await owners() == [await _me(client, b)]
    # Borrar con la cuenta equivocada no toca el token ajeno.
    assert (await client.delete(f"{url}/{TOKEN}", headers=a)).status_code == 204
    assert len(await owners()) == 1
    assert (await client.delete(f"{url}/{TOKEN}", headers=b)).status_code == 204
    assert await owners() == []


async def test_mentoria_avisa_al_emprendedor_y_bandeja(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, mentor_id, _, _ = await _world(client, make_user, login)
    e_id = await _me(client, h["e"])
    sid = await _book(client, h, vid, mentor_id)
    await wait_for_pushes()
    # Quien agenda no recibe aviso de su propia accion (solo el del cambio de etapa).
    assert [p.data["tipo"] for p in _push(client).to(e_id)] == ["etapa_avanzada"]

    r = await client.post(
        f"{API}/mentoring/sessions/{sid}/commitments",
        json={"descripcion": "Enviar guion", "fecha_limite": "2030-01-01T00:00:00Z"},
        headers=h["m"],
    )
    assert r.status_code == 201
    await client.post(
        f"{API}/mentoring/sessions/{sid}/recommendations",
        json={"titulo": "Prueba un canal", "contenido": "Uno solo."},
        headers=h["m"],
    )
    await client.post(f"{API}/mentoring/sessions/{sid}/cancel", headers=h["m"])
    await wait_for_pushes()

    pushes = _push(client).to(e_id)[1:]
    assert [p.data["tipo"] for p in pushes] == [
        "compromiso_nuevo",
        "recomendacion_nueva",
        "sesion_cancelada",
    ]
    assert pushes[0].data["ruta"] == "/mentoring/tasks"
    assert pushes[2].data["ruta"] == f"/mentoring/session/{sid}"
    assert _push(client).to(mentor_id) == []

    inbox = (await client.get(f"{API}/notifications", headers=h["e"])).json()
    assert inbox["total"] == 4
    assert inbox["items"][0]["tipo"] == "sesion_cancelada"  # la mas reciente primero
    assert all(not n["leida"] for n in inbox["items"])
    count = f"{API}/notifications/unread-count"
    assert (await client.get(count, headers=h["e"])).json() == {"no_leidas": 4}

    nid = inbox["items"][0]["notificacion_id"]
    # Otro usuario no puede marcar una notificacion ajena.
    assert (
        await client.post(f"{API}/notifications/{nid}/read", headers=h["m"])
    ).status_code == 404
    read = await client.post(f"{API}/notifications/{nid}/read", headers=h["e"])
    assert read.status_code == 200 and read.json()["leida"] is True
    unread = (
        await client.get(f"{API}/notifications?solo_no_leidas=true", headers=h["e"])
    ).json()
    assert unread["total"] == 3
    await client.post(f"{API}/notifications/read-all", headers=h["e"])
    assert (await client.get(count, headers=h["e"])).json() == {"no_leidas": 0}


async def test_etapa_capacitacion_e_insignia(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, mentor_id, _, _ = await _world(client, make_user, login)
    e_id = await _me(client, h["e"])
    sid = await _book(client, h, vid, mentor_id)  # el coordinador avanza la etapa
    await client.post(
        f"{API}/mentoring/sessions/{sid}/complete", json={}, headers=h["m"]
    )
    created = await client.post(
        f"{API}/training",
        json={"titulo": "Finanzas", "fecha": "2030-05-01T14:00:00Z"},
        headers=h["coord"],
    )
    eid = (await client.get(f"{API}/entrepreneurs/me", headers=h["e"])).json()[
        "emprendedor_id"
    ]
    await client.post(
        f"{API}/training/{created.json()['capacitacion_id']}/participants",
        json={"emprendedor_id": eid},
        headers=h["coord"],
    )
    await wait_for_pushes()
    kinds = [p.data["tipo"] for p in _push(client).to(e_id)]
    assert kinds == [
        "etapa_avanzada",
        "insignia_ganada",
        "sesion_realizada",
        "capacitacion_nueva",
        "capacitacion_inscrito",
    ]
    nueva = _push(client).to(e_id)[3]
    assert "Finanzas" in nueva.body and "01/05 10:00" in nueva.body  # hora de La Paz


async def test_recordatorios_salen_una_sola_vez(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, vid, mentor_id, _, _ = await _world(client, make_user, login)
    e_id = await _me(client, h["e"])
    sid = await _book(client, h, vid, mentor_id)
    soon = datetime.now(UTC) + timedelta(hours=3)
    await session.execute(
        text(
            "UPDATE cieu.sesiones_acompanamiento SET fecha_programada = :f "
            "WHERE sesiones_acompanamientoid = :s"
        ),
        {"f": soon, "s": sid},
    )
    await client.post(
        f"{API}/mentoring/sessions/{sid}/commitments",
        json={
            "descripcion": "Llamar a 5 clientes",
            "fecha_limite": (datetime.now(UTC) + timedelta(hours=30)).isoformat(),
        },
        headers=h["m"],
    )

    service = MentoringService(session)
    assert await service.send_reminders() == (1, 1)
    assert await service.send_reminders() == (0, 0)
    await wait_for_pushes()
    kinds = [p.data["tipo"] for p in _push(client).to(e_id)]
    assert kinds.count("recordatorio_sesion") == 1
    assert kinds.count("recordatorio_compromiso") == 1


async def test_sin_commit_no_sale_el_push(
    client: AsyncClient, make_user: MakeUser, session: AsyncSession
) -> None:
    uid = (await make_user(email="a@test.com")).usuario_id
    await session.commit()
    await NotificationService(session).notify([uid], "x", "Hola", "...")
    await session.rollback()
    await wait_for_pushes()
    assert _push(client).to(uid) == []

    await NotificationService(session).notify([uid], "x", "Hola", "...")
    await session.commit()
    await wait_for_pushes()
    assert len(_push(client).to(uid)) == 1


async def test_despachador_borra_los_tokens_invalidos(
    session: AsyncSession, make_user
) -> None:
    user = await make_user(email="a@test.com")
    for token in ("bueno-0123456789", "muerto-0123456789"):
        await session.execute(
            text(
                "INSERT INTO cieu.dispositivos_push (usuario_id, token, plataforma) "
                "VALUES (:u, :t, 'android')"
            ),
            {"u": user.usuario_id, "t": token},
        )

    class Sender:
        configured = True
        sent: list[str] = []

        async def send(self, token, title, body, data) -> PushResult:
            self.sent.append(token)
            return PushResult.INVALID_TOKEN if "muerto" in token else PushResult.SENT

    @asynccontextmanager
    async def factory() -> AsyncIterator[AsyncSession]:
        yield session

    sender = Sender()
    await PushDispatcher(factory, sender).deliver(
        [PushMessage((user.usuario_id,), "Hola", "Cuerpo")]
    )
    assert sorted(sender.sent) == ["bueno-0123456789", "muerto-0123456789"]
    left = await session.scalars(text("SELECT token FROM cieu.dispositivos_push"))
    assert list(left) == ["bueno-0123456789"]
