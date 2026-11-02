"""Mentorias: agenda, sesiones, compromisos, avances y sincronizacion."""

from datetime import UTC, date, datetime, timedelta

from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import MakeUser

API = "/api/v1"


async def _enable(client: AsyncClient, h, mentor_id: int) -> None:
    r = await client.put(
        f"{API}/mentoring/mentors/{mentor_id}/enabled",
        json={"habilitado": True},
        headers=h["coord"],
    )
    assert r.status_code == 200 and r.json()["habilitado"] is True


async def _assign(client: AsyncClient, h, mentor_id: int, vid: int) -> dict:
    r = await client.post(
        f"{API}/mentoring/assignments",
        json={"usuario_id": mentor_id, "emprendimiento_id": vid},
        headers=h["coord"],
    )
    assert r.status_code == 201, r.text
    return r.json()


async def _world(
    client: AsyncClient, make_user: MakeUser, login, *, ready: bool = True
):
    """`ready`: el asesor queda habilitado y asignado al emprendimiento."""
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
    if ready:
        await _enable(client, h, mentor_u.usuario_id)
        await _assign(client, h, mentor_u.usuario_id, vid)
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
    """Dos turnos de una hora (09:00 y 10:30, hora de La Paz, UTC-4)."""
    r = await client.put(
        f"{API}/mentoring/mentors/{mentor_id}/availability",
        json=[
            {
                "fecha_inicio": f"{day}T09:00:00-04:00",
                "fecha_fin": f"{day}T10:00:00-04:00",
            },
            {
                "fecha_inicio": f"{day}T10:30:00-04:00",
                "fecha_fin": f"{day}T11:30:00-04:00",
            },
        ],
        headers=h["m"],
    )
    assert r.status_code == 200 and len(r.json()) == 2


async def test_disponibilidad_solapada_no_guarda_nada(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _, mentor_id, _, _ = await _world(client, make_user, login)
    day = _future_day()
    await _set_availability(client, h, mentor_id, day)
    url = f"{API}/mentoring/mentors/{mentor_id}/availability"

    overlapping = await client.put(
        url,
        json=[
            {
                "fecha_inicio": f"{day}T14:00:00-04:00",
                "fecha_fin": f"{day}T16:00:00-04:00",
            },
            {
                "fecha_inicio": f"{day}T15:00:00-04:00",
                "fecha_fin": f"{day}T17:00:00-04:00",
            },
        ],
        headers=h["m"],
    )
    assert overlapping.status_code == 409
    assert overlapping.json()["error"]["code"] == "availability_overlap"
    # Nada se guardo: sigue la disponibilidad anterior.
    kept = (await client.get(url, headers=h["m"])).json()
    assert len(kept) == 2 and kept[0]["fecha_inicio"].endswith("13:00:00Z")

    backwards = await client.put(
        url,
        json=[
            {
                "fecha_inicio": f"{day}T10:00:00-04:00",
                "fecha_fin": f"{day}T09:00:00-04:00",
            }
        ],
        headers=h["m"],
    )
    assert backwards.status_code == 422


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
    """CU09: solo asesores habilitados, sin duplicar asignaciones activas."""
    h, vid, mentor_id, _, _ = await _world(client, make_user, login, ready=False)
    body = {"usuario_id": mentor_id, "emprendimiento_id": vid}
    url = f"{API}/mentoring/assignments"

    assert (await client.post(url, json=body, headers=h["e"])).status_code == 403
    # el asesor tiene `asesorias:registro`, pero asignar y habilitar es de coordinacion
    assert (await client.post(url, json=body, headers=h["m"])).status_code == 403
    assert (
        await client.put(
            f"{API}/mentoring/mentors/{mentor_id}/enabled",
            json={"habilitado": True},
            headers=h["m"],
        )
    ).status_code == 403
    not_enabled = await client.post(url, json=body, headers=h["coord"])
    assert not_enabled.status_code == 409
    assert not_enabled.json()["error"]["code"] == "mentor_not_enabled"
    # habilitar es del personal con permiso, no del emprendedor
    enable = f"{API}/mentoring/mentors/{mentor_id}/enabled"
    assert (
        await client.put(enable, json={"habilitado": True}, headers=h["e"])
    ).status_code == 403

    await _enable(client, h, mentor_id)
    created = await client.post(url, json=body, headers=h["coord"])
    assert created.status_code == 201 and created.json()["emprendimiento"] == "Sabores"
    duplicate = await client.post(url, json=body, headers=h["coord"])
    assert duplicate.status_code == 409
    assert duplicate.json()["error"]["code"] == "assignment_exists"

    mine = (await client.get(f"{url}/me", headers=h["m"])).json()
    assert len(mine) == 1
    ended = await client.patch(
        f"{url}/{mine[0]['asignacion_id']}/end", headers=h["coord"]
    )
    assert ended.json()["estado"] == "finalizada"
    # finalizada la anterior, se puede volver a asignar
    assert (await client.post(url, json=body, headers=h["coord"])).status_code == 201

    # inhabilitado, ya no recibe nuevas asignaciones
    await client.put(enable, json={"habilitado": False}, headers=h["coord"])
    other = await client.post(
        url, json={**body, "emprendimiento_id": vid + 999}, headers=h["coord"]
    )
    assert other.json()["error"]["code"] == "mentor_not_enabled"


async def test_disponibilidad_por_horario(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    """CU15: alta, edicion y baja de horarios; un solapamiento no guarda nada."""
    h, _, mentor_id, *_ = await _world(client, make_user, login)
    day = _future_day()
    url = f"{API}/mentoring/mentors/{mentor_id}/availability"

    def slot(start: str, end: str) -> dict:
        return {
            "fecha_inicio": f"{day}T{start}-04:00",
            "fecha_fin": f"{day}T{end}-04:00",
        }

    first = await client.post(url, json=slot("09:00:00", "11:00:00"), headers=h["m"])
    assert first.status_code == 201
    first_id = first.json()["disponibilidad_id"]
    # un intervalo de 2 h ofrece 2 turnos de 1 h
    slots = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()
    assert [x["hora"] for x in slots] == ["09:00", "10:00"]

    overlap = await client.post(url, json=slot("10:00:00", "12:00:00"), headers=h["m"])
    assert overlap.status_code == 409
    assert overlap.json()["error"]["code"] == "availability_overlap"
    assert len((await client.get(url, headers=h["m"])).json()) == 1  # nada parcial

    touching = await client.post(url, json=slot("11:00:00", "12:00:00"), headers=h["m"])
    assert touching.status_code == 201  # pegado al anterior, sin solaparse
    second_id = touching.json()["disponibilidad_id"]

    shrunk = await client.patch(
        f"{API}/mentoring/availability/{first_id}",
        json={"fecha_fin": f"{day}T10:00:00-04:00"},
        headers=h["m"],
    )
    assert shrunk.status_code == 200
    # mover el segundo encima del primero se rechaza y no cambia nada
    clash = await client.patch(
        f"{API}/mentoring/availability/{second_id}",
        json={"fecha_inicio": f"{day}T09:30:00-04:00"},
        headers=h["m"],
    )
    assert clash.status_code == 409
    backwards = await client.patch(
        f"{API}/mentoring/availability/{second_id}",
        json={"fecha_fin": f"{day}T10:00:00-04:00"},
        headers=h["m"],
    )
    assert backwards.status_code == 400
    blocked = await client.patch(
        f"{API}/mentoring/availability/{second_id}",
        json={"estado": "bloqueado"},
        headers=h["m"],
    )
    assert blocked.json()["estado"] == "bloqueado"

    # el emprendedor y el coordinador (sin permiso de modificacion) no lo editan
    for who in ("e", "coord"):
        assert (
            await client.delete(
                f"{API}/mentoring/availability/{first_id}", headers=h[who]
            )
        ).status_code == 403
    assert (
        await client.delete(f"{API}/mentoring/availability/{first_id}", headers=h["m"])
    ).status_code == 204
    gone = await client.delete(
        f"{API}/mentoring/availability/{first_id}", headers=h["m"]
    )
    assert gone.status_code == 404
    assert gone.json()["error"]["code"] == "availability_not_found"


async def test_emprendedor_solo_ve_y_agenda_con_asesores_asignados(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    """CU10: lista de asesores asignados; agendar exige asesor habilitado y asignado."""
    h, vid, mentor_id, *_ = await _world(client, make_user, login, ready=False)
    await _enable_booking(client, h, vid)
    day = _future_day()
    await _set_availability(client, h, mentor_id, day)
    slot = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()[0]
    book = {"mentor_id": mentor_id, "inicio": slot["inicio"]}

    assert (await client.get(f"{API}/mentoring/mentors", headers=h["e"])).json() == []
    staff_view = (
        await client.get(f"{API}/mentoring/mentors", headers=h["coord"])
    ).json()
    assert [m["habilitado"] for m in staff_view] == [False]

    no_profile = await client.post(
        f"{API}/mentoring/sessions", json=book, headers=h["e"]
    )
    assert no_profile.json()["error"]["code"] == "mentor_not_enabled"
    await _enable(client, h, mentor_id)
    unassigned = await client.post(
        f"{API}/mentoring/sessions", json=book, headers=h["e"]
    )
    assert unassigned.status_code == 403
    assert unassigned.json()["error"]["code"] == "mentor_not_assigned"
    assert (await client.get(f"{API}/mentoring/mentors", headers=h["e"])).json() == []

    await _assign(client, h, mentor_id, vid)
    listed = (await client.get(f"{API}/mentoring/mentors", headers=h["e"])).json()
    assert [m["usuario_id"] for m in listed] == [mentor_id]
    booked = await client.post(f"{API}/mentoring/sessions", json=book, headers=h["e"])
    assert booked.status_code == 201 and booked.json()["emprendimiento"] == "Sabores"


async def test_registrar_sesion_realizada(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    """CU16: sesion ya realizada con fecha, tema, modalidad y observaciones."""
    h, vid, mentor_id, *_ = await _world(client, make_user, login)
    past = (datetime.now(UTC) - timedelta(days=2)).isoformat()
    body = {
        "emprendimiento_id": vid,
        "fecha_realizada": past,
        "tema": "Costos",
        "modalidad": "virtual",
        "observaciones": "Revisamos margenes",
    }
    url = f"{API}/mentoring/sessions/register"

    ok = await client.post(url, json=body, headers=h["m"])
    assert ok.status_code == 201
    out = ok.json()
    assert out["estado"] == "realizada" and out["modalidad"] == "virtual"
    assert out["tema"] == "Costos" and out["mentor"] == "Marcelo Cuellar"
    assert {p["rol"] for p in out["participantes"]} == {"mentor", "emprendedor"}

    future = {
        **body,
        "fecha_realizada": (datetime.now(UTC) + timedelta(days=1)).isoformat(),
    }
    rejected = await client.post(url, json=future, headers=h["m"])
    assert rejected.status_code == 422
    assert rejected.json()["error"]["code"] == "future_date"
    assert (await client.post(url, json=body, headers=h["e"])).status_code == 403

    # un asesor que no esta asignado a ese emprendimiento no puede registrarla
    await make_user(
        rol="asesor", email="otro@test.com", nombre="Otro", apellido="Asesor"
    )
    other = await login("otro@test.com")
    denied = await client.post(url, json=body, headers=other)
    assert denied.status_code == 403
    assert denied.json()["error"]["code"] == "not_assigned"

    mine = (
        await client.get(
            f"{API}/mentoring/sessions/me?filtro=realizadas", headers=h["e"]
        )
    ).json()
    assert [x["tema"] for x in mine] == ["Costos"]


async def test_completar_sesion_agendada_con_datos(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, mentor_id, *_ = await _world(client, make_user, login)
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
    url = f"{API}/mentoring/sessions/{sid}/complete"

    tomorrow = (datetime.now(UTC) + timedelta(days=1)).isoformat()
    assert (
        await client.post(url, json={"fecha_realizada": tomorrow}, headers=h["m"])
    ).status_code == 422
    done = await client.post(
        url,
        json={
            "fecha_realizada": (datetime.now(UTC) - timedelta(hours=3)).isoformat(),
            "tema": "Precios",
            "modalidad": "hibrida",
            "observaciones": "Definimos el precio",
        },
        headers=h["m"],
    )
    assert done.status_code == 200
    out = done.json()
    assert out["estado"] == "realizada" and out["tema"] == "Precios"
    assert (
        out["modalidad"] == "hibrida" and out["observaciones"] == "Definimos el precio"
    )

    # El periodo cuenta desde cuando OCURRIO (fecha realizada), no desde cuando se agendo:
    # la sesion estaba agendada para dentro de 7 dias pero se realizo hace 3 horas.
    today = date.today()
    window = f"estado=realizada&desde={today - timedelta(days=1)}&hasta={today}"
    found = (
        await client.get(f"{API}/mentoring/sessions/me?{window}", headers=h["m"])
    ).json()
    assert [x["tema"] for x in found] == ["Precios"]
    scheduled_day = f"estado=realizada&desde={day}&hasta={day}"
    assert (
        await client.get(f"{API}/mentoring/sessions/me?{scheduled_day}", headers=h["m"])
    ).json() == []


async def test_recomendaciones_y_compromisos_del_emprendimiento(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    """CU17 y CU18: vinculo con la sesion del mismo emprendimiento y responsable valido."""
    h, vid, mentor_id, *_ = await _world(client, make_user, login)
    emp_id = (await client.get(f"{API}/auth/me", headers=h["e"])).json()["usuario_id"]
    past = (datetime.now(UTC) - timedelta(days=1)).isoformat()
    sid = (
        await client.post(
            f"{API}/mentoring/sessions/register",
            json={"emprendimiento_id": vid, "fecha_realizada": past, "tema": "Ventas"},
            headers=h["m"],
        )
    ).json()["sesion_id"]

    # otro emprendimiento con su propia sesion (la registra el coordinador)
    await make_user(email="e2@test.com", nombre="Luis", apellido="Rojas")
    h["e2"] = await login("e2@test.com")
    vid2 = (
        await client.post(f"{API}/ventures", json={"nombre": "Otro"}, headers=h["e2"])
    ).json()["emprendimiento_id"]
    emp2_id = (await client.get(f"{API}/auth/me", headers=h["e2"])).json()["usuario_id"]
    other_session = await client.post(
        f"{API}/mentoring/sessions/register",
        json={"emprendimiento_id": vid2, "fecha_realizada": past, "tema": "Otro"},
        headers=h["coord"],
    )
    assert other_session.status_code == 201, other_session.text
    sid2 = other_session.json()["sesion_id"]

    # --- CU17 recomendaciones
    rec_url = f"{API}/mentoring/recommendations"
    rec = {
        "emprendimiento_id": vid,
        "titulo": "Define tu cliente",
        "contenido": "Detalle",
    }
    linked = await client.post(rec_url, json={**rec, "sesion_id": sid}, headers=h["m"])
    assert linked.status_code == 201 and linked.json()["sesion_id"] == sid
    free = await client.post(rec_url, json=rec, headers=h["m"])
    assert free.status_code == 201 and free.json()["sesion_id"] is None
    mismatch = await client.post(
        rec_url, json={**rec, "sesion_id": sid2}, headers=h["m"]
    )
    assert mismatch.status_code == 422
    assert mismatch.json()["error"]["code"] == "session_mismatch"
    assert (await client.post(rec_url, json=rec, headers=h["e"])).status_code == 403
    mine = (
        await client.get(f"{API}/mentoring/recommendations/me", headers=h["e"])
    ).json()
    assert len(mine) == 2

    # --- CU18 compromisos
    url = f"{API}/mentoring/commitments"
    com = {"emprendimiento_id": vid, "descripcion": "Subir fotos", "usuario_id": emp_id}
    default_days = await client.post(url, json=com, headers=h["m"])
    assert default_days.status_code == 201
    out = default_days.json()
    assert out["responsable_id"] == emp_id and out["estado"] == "pendiente"
    due = datetime.fromisoformat(out["fecha_limite"])
    assert (
        timedelta(days=6, hours=23)
        < due - datetime.now(UTC)
        < timedelta(days=7, hours=1)
    )

    explicit_due = (datetime.now(UTC) + timedelta(days=30)).isoformat()
    explicit = await client.post(
        url, json={**com, "fecha_limite": explicit_due}, headers=h["m"]
    )
    assert datetime.fromisoformat(explicit.json()["fecha_limite"]) > datetime.now(
        UTC
    ) + timedelta(days=29)

    # el responsable por defecto sale del parametro dias_limite_compromiso
    await session.execute(
        text(
            "UPDATE cieu.parametros_seguimiento SET valor = '3' WHERE clave = 'dias_limite_compromiso'"
        )
    )
    three = await client.post(url, json=com, headers=h["m"])
    due3 = datetime.fromisoformat(three.json()["fecha_limite"])
    assert (
        timedelta(days=2, hours=23)
        < due3 - datetime.now(UTC)
        < timedelta(days=3, hours=1)
    )

    # el responsable debe pertenecer al emprendimiento (emprendedor inscrito o asesor asignado)
    stranger = await client.post(
        url, json={**com, "usuario_id": emp2_id}, headers=h["m"]
    )
    assert stranger.status_code == 422
    assert stranger.json()["error"]["code"] == "responsible_not_member"
    advisor = await client.post(
        url, json={**com, "usuario_id": mentor_id}, headers=h["m"]
    )
    assert advisor.status_code == 201
    wrong_session = await client.post(
        url, json={**com, "sesion_id": sid2}, headers=h["m"]
    )
    assert wrong_session.json()["error"]["code"] == "session_mismatch"
    assert (await client.post(url, json=com, headers=h["e"])).status_code == 403

    pending = (
        await client.get(
            f"{API}/mentoring/commitments/me?estado=pendiente", headers=h["e"]
        )
    ).json()
    assert len(pending) == 3


async def test_filtros_de_sesiones_por_periodo_y_estado(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    """CU23: mentorias programadas del asesor y del emprendedor, por estado y periodo."""
    h, vid, mentor_id, *_ = await _world(client, make_user, login)
    await _enable_booking(client, h, vid)
    day = _future_day()
    await _set_availability(client, h, mentor_id, day)
    slot = (
        await client.get(
            f"{API}/mentoring/mentors/{mentor_id}/slots?fecha={day}", headers=h["e"]
        )
    ).json()[0]
    await client.post(
        f"{API}/mentoring/sessions",
        json={"mentor_id": mentor_id, "inicio": slot["inicio"]},
        headers=h["e"],
    )
    register = f"{API}/mentoring/sessions/register"
    for days_ago, topic in ((2, "Reciente"), (40, "Antigua")):
        when = (datetime.now(UTC) - timedelta(days=days_ago)).isoformat()
        await client.post(
            register,
            json={"emprendimiento_id": vid, "fecha_realizada": when, "tema": topic},
            headers=h["m"],
        )

    async def topics(path: str, who: str) -> list[str]:
        data = (await client.get(f"{API}/mentoring/{path}", headers=h[who])).json()
        rows = data["items"] if isinstance(data, dict) else data
        return sorted((r["tema"] or "-") for r in rows)

    for who in ("e", "m"):  # emprendedor y asesor ven lo mismo en /me
        assert len(await topics("sessions/me", who)) == 3
        assert await topics("sessions/me?estado=realizada", who) == [
            "Antigua",
            "Reciente",
        ]
        assert len(await topics("sessions/me?filtro=proximas", who)) == 1
    today = date.today()
    window = f"desde={today - timedelta(days=5)}&hasta={today}"
    assert await topics(f"sessions/me?estado=realizada&{window}", "e") == ["Reciente"]
    only_old = f"desde={today - timedelta(days=60)}&hasta={today - timedelta(days=30)}"
    assert await topics(f"sessions/me?{only_old}", "m") == ["Antigua"]

    # el personal consulta todas, con los mismos filtros y por emprendimiento
    assert await topics(
        f"sessions?estado=realizada&emprendimiento_id={vid}", "coord"
    ) == [
        "Antigua",
        "Reciente",
    ]
    assert await topics(f"sessions?estado=realizada&{window}", "coord") == ["Reciente"]
    assert await topics(f"sessions?emprendimiento_id={vid + 999}", "coord") == []
    bad = await client.get(
        f"{API}/mentoring/sessions/me?estado=cualquiera", headers=h["e"]
    )
    assert bad.status_code == 422


async def test_historial_del_emprendimiento_y_sus_permisos(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    """CU19: linea de tiempo con sesiones, avances, hitos, recomendaciones y compromisos."""
    h, vid, mentor_id, *_ = await _world(client, make_user, login)
    emp_id = (await client.get(f"{API}/auth/me", headers=h["e"])).json()["usuario_id"]
    past = (datetime.now(UTC) - timedelta(days=2)).isoformat()
    sid = (
        await client.post(
            f"{API}/mentoring/sessions/register",
            json={"emprendimiento_id": vid, "fecha_realizada": past, "tema": "Costos"},
            headers=h["m"],
        )
    ).json()["sesion_id"]
    await client.post(
        f"{API}/mentoring/progress",
        json={"observaciones": "Primer cliente"},
        headers=h["e"],
    )
    await client.post(
        f"{API}/mentoring/recommendations",
        json={
            "emprendimiento_id": vid,
            "sesion_id": sid,
            "titulo": "Define tu cliente",
            "contenido": "Detalle",
        },
        headers=h["m"],
    )
    await client.post(
        f"{API}/mentoring/commitments",
        json={
            "emprendimiento_id": vid,
            "descripcion": "Subir fotos",
            "usuario_id": emp_id,
        },
        headers=h["m"],
    )
    estimated = (datetime.now(UTC) + timedelta(days=10)).isoformat()
    await client.post(
        f"{API}/ventures/{vid}/milestones",
        json={"titulo": "Primer prototipo", "fecha_estimada": estimated},
        headers=h["e"],
    )
    await client.post(
        f"{API}/ventures/{vid}/milestones", json={"titulo": "Sin fecha"}, headers=h["e"]
    )

    url = f"{API}/mentoring/ventures/{vid}/history"
    events = (await client.get(url, headers=h["coord"])).json()
    assert {e["tipo"] for e in events} == {
        "sesion",
        "avance",
        "hito",
        "recomendacion",
        "compromiso",
        "etapa",
    }
    dated = [e for e in events if e["fecha"]]
    assert [e["fecha"] for e in dated] == sorted(
        e["fecha"] for e in dated
    )  # cronologico
    assert dated[0]["tipo"] == "sesion" and dated[0]["titulo"] == "Costos"
    assert events[-1]["titulo"] == "Sin fecha" and events[-1]["fecha"] is None
    by_type = {e["tipo"]: e for e in events}
    assert (
        by_type["avance"]["autor"] and by_type["recomendacion"]["detalle"] == "Detalle"
    )
    assert by_type["compromiso"]["estado"] == "pendiente"
    assert by_type["etapa"]["titulo"].startswith("Pasó a ")

    # mas reciente primero (lo sin fecha sigue al final)
    newest = (await client.get(f"{url}?orden=desc", headers=h["coord"])).json()
    dated_desc = [e["fecha"] for e in newest if e["fecha"]]
    assert (
        dated_desc == sorted(dated_desc, reverse=True) and newest[-1]["fecha"] is None
    )

    # permisos por emprendimiento
    assert (await client.get(url, headers=h["e"])).status_code == 200  # el suyo
    mine = await client.get(f"{API}/mentoring/ventures/me/history", headers=h["e"])
    assert mine.status_code == 200 and len(mine.json()) == len(events)
    assert (await client.get(url, headers=h["m"])).status_code == 200  # asesor asignado
    await make_user(email="e2@test.com", nombre="Otro", apellido="Emprendedor")
    other = await login("e2@test.com")
    assert (await client.get(url, headers=other)).status_code == 403  # no es suyo
    await make_user(
        rol="asesor", email="otro@test.com", nombre="Otro", apellido="Asesor"
    )
    stranger = await login("otro@test.com")
    denied = await client.get(url, headers=stranger)
    assert (
        denied.status_code == 403 and denied.json()["error"]["code"] == "not_assigned"
    )
