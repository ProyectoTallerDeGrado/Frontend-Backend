"""Mentorias: agenda, sesiones, compromisos, avances y sincronizacion."""

from datetime import date, timedelta

from httpx import AsyncClient

from tests.conftest import MakeUser

API = "/api/v1"


async def _world(client: AsyncClient, make_user: MakeUser, login):
    admin_u = await make_user(rol="administrador", email="admin@test.com")
    coord_u = await make_user(rol="coordinador", email="coord@test.com")
    mentor_u = await make_user(
        rol="asesor", email="m@test.com", nombre="Marcelo", apellido="Cuellar"
    )
    await make_user(email="e@test.com", nombre="Camila", apellido="Justiniano")
    h = {k: await login(f"{k}@test.com") for k in ("admin", "coord", "e")}
    h["m"] = await login("m@test.com")
    vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Sabores"}, headers=h["e"])
    ).json()["emprendimiento_id"]
    return h, vid, mentor_u.usuario_id, admin_u.usuario_id, coord_u.usuario_id


def _future_day() -> date:
    return date.today() + timedelta(days=7)


async def _enable_booking(client, h, vid) -> None:
    stages = {
        s["nombre"]: s
        for s in (await client.get(f"{API}/stages", headers=h["e"])).json()
    }
    await client.put(
        f"{API}/ventures/{vid}/stage",
        json={"etapa_id": stages["Incubación"]["etapa_id"]},
        headers=h["coord"],
    )


async def _set_availability(client, h, mentor_id, day: date) -> None:
    r = await client.put(
        f"{API}/mentoring/mentors/{mentor_id}/availability",
        json=[
            {
                "dia_semana": day.weekday(),
                "hora_inicio": "09:00:00",
                "duracion_min": 60,
            },
            {
                "dia_semana": day.weekday(),
                "hora_inicio": "10:30:00",
                "duracion_min": 60,
            },
        ],
        headers=h["m"],
    )
    assert r.status_code == 200 and len(r.json()) == 2


async def test_agendamiento_bloqueos_y_slots(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, mentor_id, _, _ = await _world(client, make_user, login)
    day = _future_day()

    status = (
        await client.get(f"{API}/mentoring/booking-status", headers=h["e"])
    ).json()
    assert status["habilitado"] is False and "Incubación" in status["motivo"]

    await _set_availability(client, h, mentor_id, day)
    slots = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()
    assert [s["hora"] for s in slots] == ["09:00", "10:30"] and all(
        s["disponible"] for s in slots
    )

    early = await client.post(
        f"{API}/mentoring/sessions",
        json={"mentor_id": mentor_id, "inicio": slots[0]["inicio"]},
        headers=h["e"],
    )
    assert (
        early.status_code == 403
        and early.json()["error"]["code"] == "booking_not_enabled"
    )

    await _enable_booking(client, h, vid)
    assert (await client.get(f"{API}/mentoring/booking-status", headers=h["e"])).json()[
        "habilitado"
    ] is True

    # el mentor exige completar el primer reto
    first_reto = (await client.get(f"{API}/challenges", headers=h["e"])).json()[0]
    prof = await client.put(
        f"{API}/mentoring/mentors/{mentor_id}/profile",
        json={
            "especialidad": "Ventas y marketing",
            "reto_requerido_id": first_reto["reto_id"],
        },
        headers=h["m"],
    )
    assert prof.status_code == 200
    mentors = (await client.get(f"{API}/mentoring/mentors", headers=h["e"])).json()
    assert (
        mentors[0]["bloqueado"] is True
        and "Completar el perfil" in mentors[0]["motivo_bloqueo"]
    )
    locked = await client.post(
        f"{API}/mentoring/sessions",
        json={"mentor_id": mentor_id, "inicio": slots[0]["inicio"]},
        headers=h["e"],
    )
    assert (
        locked.status_code == 403 and locked.json()["error"]["code"] == "mentor_locked"
    )

    await client.post(
        f"{API}/journey/challenges/{first_reto['reto_id']}/complete", headers=h["e"]
    )
    assert (await client.get(f"{API}/mentoring/mentors", headers=h["e"])).json()[0][
        "bloqueado"
    ] is False

    booked = await client.post(
        f"{API}/mentoring/sessions",
        json={"mentor_id": mentor_id, "inicio": slots[0]["inicio"]},
        headers=h["e"],
    )
    assert booked.status_code == 201
    session = booked.json()
    assert session["estado"] == "programada" and session["mentor"] == "Marcelo Cuellar"
    assert session["especialidad"] == "Ventas y marketing"

    again = await client.post(
        f"{API}/mentoring/sessions",
        json={"mentor_id": mentor_id, "inicio": slots[0]["inicio"]},
        headers=h["e"],
    )
    assert (
        again.status_code == 409 and again.json()["error"]["code"] == "slot_unavailable"
    )
    wrong = await client.post(
        f"{API}/mentoring/sessions",
        json={"mentor_id": mentor_id, "inicio": f"{day}T13:17:00Z"},
        headers=h["e"],
    )
    assert wrong.status_code == 422 and wrong.json()["error"]["code"] == "invalid_slot"

    slots2 = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()
    assert [s["disponible"] for s in slots2] == [False, True]

    mine = (
        await client.get(f"{API}/mentoring/sessions/me?filtro=proximas", headers=h["e"])
    ).json()
    assert [x["sesion_id"] for x in mine] == [session["sesion_id"]]
    assert (
        len((await client.get(f"{API}/mentoring/sessions/me", headers=h["m"])).json())
        == 1
    )

    # un tercero no ve la sesion; el personal si
    assert (
        await client.get(
            f"{API}/mentoring/sessions/{session['sesion_id']}", headers=h["admin"]
        )
    ).status_code == 200
    listing = (await client.get(f"{API}/mentoring/sessions", headers=h["coord"])).json()
    assert listing["total"] == 1


async def test_sesion_realizada_compromisos_recomendaciones_e_insignia(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, mentor_id, _, _ = await _world(client, make_user, login)
    day = _future_day()
    await _enable_booking(client, h, vid)
    await _set_availability(client, h, mentor_id, day)
    slot = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()[0]
    sid = (
        await client.post(
            f"{API}/mentoring/sessions",
            json={"mentor_id": mentor_id, "inicio": slot["inicio"]},
            headers=h["e"],
        )
    ).json()["sesion_id"]

    # el emprendedor no puede cerrar la sesion ni asignar compromisos
    assert (
        await client.post(
            f"{API}/mentoring/sessions/{sid}/complete", json={}, headers=h["e"]
        )
    ).status_code == 403
    assert (
        await client.post(
            f"{API}/mentoring/sessions/{sid}/commitments",
            json={"descripcion": "x"},
            headers=h["e"],
        )
    ).status_code == 403

    com = await client.post(
        f"{API}/mentoring/sessions/{sid}/commitments",
        json={
            "descripcion": "Enviar guion de entrevista",
            "fecha_limite": "2030-01-01T00:00:00Z",
        },
        headers=h["m"],
    )
    assert com.status_code == 201 and com.json()["estado"] == "pendiente"
    rec = await client.post(
        f"{API}/mentoring/sessions/{sid}/recommendations",
        json={
            "titulo": "Prueba un canal",
            "contenido": "Elige un solo canal durante dos semanas.",
        },
        headers=h["m"],
    )
    assert rec.status_code == 201

    done = await client.post(
        f"{API}/mentoring/sessions/{sid}/complete",
        json={"observaciones": "Buena sesion"},
        headers=h["m"],
    )
    assert done.status_code == 200
    body = done.json()
    assert (
        body["estado"] == "realizada"
        and body["total_compromisos"] == 1
        and body["total_recomendaciones"] == 1
    )
    assert (
        await client.post(
            f"{API}/mentoring/sessions/{sid}/complete", json={}, headers=h["m"]
        )
    ).status_code == 409

    profile = (await client.get(f"{API}/gamification/me", headers=h["e"])).json()
    assert "Conector" in {b["nombre"] for b in profile["insignias"] if b["obtenida"]}

    pending = (
        await client.get(
            f"{API}/mentoring/commitments/me?estado=pendiente", headers=h["e"]
        )
    ).json()
    assert len(pending) == 1
    cid = pending[0]["compromiso_id"]
    ok = await client.patch(
        f"{API}/mentoring/commitments/{cid}", json={"completado": True}, headers=h["e"]
    )
    assert ok.json()["estado"] == "cumplido" and ok.json()["fecha_completado"]
    await make_user(email="otro@test.com")
    other = await login("otro@test.com")
    assert (
        await client.patch(
            f"{API}/mentoring/commitments/{cid}",
            json={"completado": False},
            headers=other,
        )
    ).status_code == 403
    assert (
        await client.get(
            f"{API}/mentoring/commitments/me?estado=pendiente", headers=h["e"]
        )
    ).json() == []
    recs = (
        await client.get(f"{API}/mentoring/recommendations/me", headers=h["e"])
    ).json()
    assert recs[0]["titulo"] == "Prueba un canal"
    realizadas = (
        await client.get(
            f"{API}/mentoring/sessions/me?filtro=realizadas", headers=h["e"]
        )
    ).json()
    assert len(realizadas) == 1


async def test_cancelar_libera_el_horario(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, mentor_id, _, _ = await _world(client, make_user, login)
    day = _future_day()
    await _enable_booking(client, h, vid)
    await _set_availability(client, h, mentor_id, day)
    slot = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()[0]
    sid = (
        await client.post(
            f"{API}/mentoring/sessions",
            json={"mentor_id": mentor_id, "inicio": slot["inicio"]},
            headers=h["e"],
        )
    ).json()["sesion_id"]
    cancelled = await client.post(
        f"{API}/mentoring/sessions/{sid}/cancel", headers=h["e"]
    )
    assert cancelled.json()["estado"] == "cancelada"
    slots = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()
    assert slots[0]["disponible"] is True


async def test_avances_idempotentes_y_sincronizacion(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, mentor_id, _, _ = await _world(client, make_user, login)
    first = await client.post(
        f"{API}/mentoring/progress",
        json={
            "observaciones": "Entreviste a 2 clientes",
            "referencia_cliente": "abc-1",
        },
        headers=h["e"],
    )
    assert first.status_code == 201 and first.json()["creado"] is True
    repeat = await client.post(
        f"{API}/mentoring/progress",
        json={
            "observaciones": "Entreviste a 2 clientes",
            "referencia_cliente": "abc-1",
        },
        headers=h["e"],
    )
    assert (
        repeat.status_code == 200
        and repeat.json()["seguimiento_id"] == first.json()["seguimiento_id"]
    )
    assert (
        len((await client.get(f"{API}/mentoring/progress", headers=h["e"])).json()) == 1
    )

    # compromiso de otra sesion para probar el lote
    await _enable_booking(client, h, vid)
    day = _future_day()
    await _set_availability(client, h, mentor_id, day)
    slot = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()[0]
    sid = (
        await client.post(
            f"{API}/mentoring/sessions",
            json={"mentor_id": mentor_id, "inicio": slot["inicio"]},
            headers=h["e"],
        )
    ).json()["sesion_id"]
    cid = (
        await client.post(
            f"{API}/mentoring/sessions/{sid}/commitments",
            json={"descripcion": "Subir fotos"},
            headers=h["m"],
        )
    ).json()["compromiso_id"]

    batch = await client.post(
        f"{API}/mentoring/sync",
        json={
            "avances": [
                {
                    "observaciones": "Entreviste a 2 clientes",
                    "referencia_cliente": "abc-1",
                },
                {
                    "observaciones": "Prototipo listo",
                    "referencia_cliente": "abc-2",
                    "fecha": "2020-01-01T10:00:00Z",
                },
            ],
            "compromisos": [
                {"compromiso_id": cid, "completado": True},
                {"compromiso_id": 99999, "completado": True},
            ],
        },
        headers=h["e"],
    )
    assert batch.status_code == 200
    out = batch.json()
    assert [a["creado"] for a in out["avances"]] == [False, True]
    assert out["avances"][1]["fecha"].startswith("2020-01-01")
    assert out["compromisos"][0]["estado"] == "cumplido"
    assert len(out["errores"]) == 1 and "99999" in out["errores"][0]

    # el personal con acceso puede ver los avances de un emprendimiento
    seen = (
        await client.get(
            f"{API}/mentoring/progress?emprendimiento_id={vid}", headers=h["coord"]
        )
    ).json()
    assert len(seen) == 2


async def test_asignaciones(client: AsyncClient, make_user: MakeUser, login) -> None:
    h, vid, mentor_id, _, _ = await _world(client, make_user, login)
    denied = await client.post(
        f"{API}/mentoring/assignments",
        json={"usuario_id": mentor_id, "emprendimiento_id": vid},
        headers=h["e"],
    )
    assert denied.status_code == 403
    created = await client.post(
        f"{API}/mentoring/assignments",
        json={"usuario_id": mentor_id, "emprendimiento_id": vid},
        headers=h["coord"],
    )
    assert created.status_code == 201 and created.json()["emprendimiento"] == "Sabores"
    mine = (await client.get(f"{API}/mentoring/assignments/me", headers=h["m"])).json()
    assert len(mine) == 1
    ended = await client.patch(
        f"{API}/mentoring/assignments/{mine[0]['asignacion_id']}/end",
        headers=h["coord"],
    )
    assert ended.json()["estado"] == "finalizada"
