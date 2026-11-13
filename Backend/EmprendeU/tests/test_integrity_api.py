"""Integridad de mentorías y seguimiento (CU09, CU10, CU15, CU16, CU20, CU24)."""

from datetime import UTC, datetime, timedelta

from httpx import AsyncClient

from tests.conftest import MakeUser
from tests.test_mentoring_api import (
    API,
    _enable,
    _enable_booking,
    _future_day,
    _set_availability,
    _world,
)


async def _book_first_slot(client: AsyncClient, h, vid: int, mentor_id: int, day):
    await _enable_booking(client, h, vid)
    await _set_availability(client, h, mentor_id, day)
    slot = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()[0]
    booked = await client.post(
        f"{API}/mentoring/sessions",
        json={"mentor_id": mentor_id, "inicio": slot["inicio"]},
        headers=h["e"],
    )
    assert booked.status_code == 201, booked.text
    return booked.json()


async def test_cu15_horario_con_sesion_no_se_toca_hasta_cancelarla(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, mentor_id, *_ = await _world(client, make_user, login)
    day = _future_day()
    session = await _book_first_slot(client, h, vid, mentor_id, day)
    url = f"{API}/mentoring/mentors/{mentor_id}/availability"
    first = (await client.get(url, headers=h["m"])).json()[0]
    one = f"{API}/mentoring/availability/{first['disponibilidad_id']}"

    deleted = await client.delete(one, headers=h["m"])
    assert deleted.status_code == 409
    assert deleted.json()["error"]["code"] == "session_conflict"
    blocked = await client.patch(one, json={"estado": "bloqueado"}, headers=h["m"])
    assert blocked.status_code == 409
    assert blocked.json()["error"]["code"] == "session_conflict"
    replaced = await client.put(url, json=[], headers=h["m"])
    assert replaced.status_code == 409
    assert replaced.json()["error"]["code"] == "session_conflict"

    # Cambios que no dejan la sesion sin cubrir siguen permitidos.
    day_start = f"{day}T08:00:00-04:00"
    wider = await client.patch(
        one,
        json={"fecha_inicio": day_start, "fecha_fin": f"{day}T10:00:00-04:00"},
        headers=h["m"],
    )
    assert wider.status_code == 200

    cancel = await client.post(
        f"{API}/mentoring/sessions/{session['sesion_id']}/cancel", headers=h["e"]
    )
    assert cancel.status_code == 200
    assert (await client.delete(one, headers=h["m"])).status_code == 204


async def test_cu15_mentor_inhabilitado_no_gestiona_horarios(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _, mentor_id, *_ = await _world(client, make_user, login)
    await client.put(
        f"{API}/mentoring/mentors/{mentor_id}/enabled",
        json={"habilitado": False},
        headers=h["coord"],
    )
    denied = await client.post(
        f"{API}/mentoring/mentors/{mentor_id}/availability",
        json={
            "fecha_inicio": f"{_future_day()}T09:00:00-04:00",
            "fecha_fin": f"{_future_day()}T10:00:00-04:00",
        },
        headers=h["m"],
    )
    assert denied.status_code == 409
    assert denied.json()["error"]["code"] == "mentor_not_enabled"
    await _enable(client, h, mentor_id)
    assert (
        await client.post(
            f"{API}/mentoring/mentors/{mentor_id}/availability",
            json={
                "fecha_inicio": f"{_future_day()}T09:00:00-04:00",
                "fecha_fin": f"{_future_day()}T10:00:00-04:00",
            },
            headers=h["m"],
        )
    ).status_code == 201


async def test_cu16_sesion_duplicada_en_el_mismo_horario(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, *_ = await _world(client, make_user, login)
    when = datetime.now(UTC) - timedelta(days=3)
    url = f"{API}/mentoring/sessions/register"

    def body(moment: datetime) -> dict:
        return {
            "emprendimiento_id": vid,
            "fecha_realizada": moment.isoformat(),
            "tema": "Costos",
        }

    assert (await client.post(url, json=body(when), headers=h["m"])).status_code == 201
    same = await client.post(url, json=body(when), headers=h["m"])
    assert same.status_code == 409
    assert same.json()["error"]["code"] == "session_duplicate"
    overlapping = await client.post(
        url, json=body(when + timedelta(minutes=30)), headers=h["m"]
    )
    assert overlapping.status_code == 409
    later = await client.post(url, json=body(when + timedelta(hours=2)), headers=h["m"])
    assert later.status_code == 201


async def test_cu20_cu24_duplicados_y_auditoria(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, mentor_id, *_ = await _world(client, make_user, login)
    await make_user(rol="administrador", email="root@test.com")
    root = await login("root@test.com")
    milestones = f"{API}/ventures/{vid}/milestones"

    first = await client.post(milestones, json={"titulo": "Prototipo"}, headers=h["e"])
    assert first.status_code == 201
    twin = await client.post(
        milestones, json={"titulo": "  prototipo "}, headers=h["e"]
    )
    assert twin.status_code == 409
    assert twin.json()["error"]["code"] == "milestone_duplicate"

    need = (
        await client.post(
            f"{API}/needs", json={"nombre": "Financiamiento"}, headers=root
        )
    ).json()
    payload = {"necesidad_id": need["necesidad_id"], "prioridad": "alta"}
    assert (
        await client.post(f"{API}/ventures/{vid}/needs", json=payload, headers=h["e"])
    ).status_code == 201
    again = await client.post(
        f"{API}/ventures/{vid}/needs", json=payload, headers=h["e"]
    )
    assert again.status_code == 409
    assert again.json()["error"]["code"] == "need_already_registered"

    await client.post(
        f"{API}/mentoring/recommendations",
        json={"emprendimiento_id": vid, "titulo": "Costos", "contenido": "Revisa"},
        headers=h["m"],
    )
    await client.post(
        f"{API}/mentoring/progress",
        json={"observaciones": "Primer cliente", "porcentaje_avance": 10},
        headers=h["e"],
    )
    actions = {
        e["accion"]
        for e in (await client.get(f"{API}/audit?page_size=100", headers=root)).json()[
            "items"
        ]
    }
    assert {
        "negocio.hito",
        "negocio.necesidad",
        "negocio.recomendacion",
        "negocio.avance",
        "negocio.asignacion",
    } <= actions
    _ = mentor_id
