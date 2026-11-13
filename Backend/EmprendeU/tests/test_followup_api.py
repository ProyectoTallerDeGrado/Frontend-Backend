"""Seguimiento: historial con filtros, listados por emprendimiento y tareas (CU17-CU19, CU22)."""

from datetime import UTC, date, datetime, timedelta

from httpx import AsyncClient

from tests.conftest import MakeUser
from tests.test_mentoring_api import API, _world


async def _seed_followup(client: AsyncClient, h, vid: int) -> int:
    """Una sesion, una recomendacion, un compromiso y un hito; devuelve el id del emprendedor."""
    me = (await client.get(f"{API}/auth/me", headers=h["e"])).json()
    learner = me["usuario_id"]
    past = (datetime.now(UTC) - timedelta(days=3)).isoformat()
    assert (
        await client.post(
            f"{API}/mentoring/sessions/register",
            json={"emprendimiento_id": vid, "fecha_realizada": past, "tema": "Costos"},
            headers=h["m"],
        )
    ).status_code == 201
    assert (
        await client.post(
            f"{API}/mentoring/recommendations",
            json={
                "emprendimiento_id": vid,
                "titulo": "Margenes",
                "contenido": "Revisa",
            },
            headers=h["m"],
        )
    ).status_code == 201
    assert (
        await client.post(
            f"{API}/mentoring/commitments",
            json={
                "emprendimiento_id": vid,
                "usuario_id": learner,
                "descripcion": "Entrevistar 5 clientes",
                "fecha_limite": (datetime.now(UTC) + timedelta(days=5)).isoformat(),
            },
            headers=h["m"],
        )
    ).status_code == 201
    assert (
        await client.post(
            f"{API}/ventures/{vid}/milestones",
            json={
                "titulo": "Prototipo",
                "fecha_estimada": (datetime.now(UTC) + timedelta(days=20)).isoformat(),
            },
            headers=h["e"],
        )
    ).status_code == 201
    return learner


async def test_cu19_historial_filtra_por_tipo_y_periodo(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, *_ = await _world(client, make_user, login)
    await _seed_followup(client, h, vid)
    url = f"{API}/mentoring/ventures/{vid}/history"

    everything = (await client.get(url, headers=h["coord"])).json()
    assert {e["tipo"] for e in everything} >= {
        "sesion",
        "recomendacion",
        "compromiso",
        "hito",
    }

    only = (await client.get(f"{url}?tipo=recomendacion", headers=h["coord"])).json()
    assert [e["tipo"] for e in only] == ["recomendacion"]
    two = (
        await client.get(f"{url}?tipo=recomendacion&tipo=sesion", headers=h["coord"])
    ).json()
    assert {e["tipo"] for e in two} == {"recomendacion", "sesion"}
    assert (await client.get(f"{url}?tipo=otro", headers=h["coord"])).status_code == 422

    today = date.today()
    recent = (
        await client.get(
            f"{url}?desde={today - timedelta(days=1)}&hasta={today}",
            headers=h["coord"],
        )
    ).json()
    # la etapa inicial tambien se registro hoy
    assert {e["tipo"] for e in recent} == {"recomendacion", "etapa"}
    old = (
        await client.get(
            f"{url}?desde={today - timedelta(days=5)}&hasta={today - timedelta(days=2)}",
            headers=h["coord"],
        )
    ).json()
    assert [e["tipo"] for e in old] == ["sesion"]
    mine = (
        await client.get(
            f"{API}/mentoring/ventures/me/history?tipo=hito", headers=h["e"]
        )
    ).json()
    assert [e["tipo"] for e in mine] == ["hito"]


async def test_cu17_cu18_listados_por_emprendimiento_y_permisos(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, *_ = await _world(client, make_user, login)
    await _seed_followup(client, h, vid)
    await make_user(rol="asesor", email="otro@test.com", nombre="Otro", apellido="X")
    other = await login("otro@test.com")
    recs = f"{API}/mentoring/ventures/{vid}/recommendations"
    coms = f"{API}/mentoring/ventures/{vid}/commitments"

    for who in ("m", "coord", "e"):
        listed = (await client.get(recs, headers=h[who])).json()
        assert [r["titulo"] for r in listed] == ["Margenes"]
    commitments = (await client.get(coms, headers=h["m"])).json()
    assert [c["descripcion"] for c in commitments] == ["Entrevistar 5 clientes"]
    assert commitments[0]["responsable"] == "Camila Justiniano"
    assert (await client.get(f"{coms}?estado=cumplido", headers=h["m"])).json() == []

    denied = await client.get(recs, headers=other)
    assert denied.status_code == 403
    assert denied.json()["error"]["code"] == "not_assigned"
    assert (await client.get(coms, headers=other)).status_code == 403


async def test_cu22_tareas_pendientes_con_filtros(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, *_ = await _world(client, make_user, login)
    await _seed_followup(client, h, vid)
    url = f"{API}/mentoring/tasks/me"

    pending = (await client.get(url, headers=h["e"])).json()
    assert [(t["tipo"], t["titulo"]) for t in pending] == [
        ("compromiso", "Entrevistar 5 clientes"),
        ("hito", "Prototipo"),
    ]
    assert all(t["estado"] == "pendiente" and not t["vencida"] for t in pending)

    only_hito = (await client.get(f"{url}?tipo=hito", headers=h["e"])).json()
    assert [t["tipo"] for t in only_hito] == ["hito"]
    soon = date.today() + timedelta(days=10)
    in_period = (
        await client.get(f"{url}?hasta={soon}&desde={date.today()}", headers=h["e"])
    ).json()
    assert [t["tipo"] for t in in_period] == ["compromiso"]

    commitment_id = pending[0]["referencia_id"]
    done = await client.patch(
        f"{API}/mentoring/commitments/{commitment_id}",
        json={"completado": True},
        headers=h["e"],
    )
    assert done.status_code == 200
    assert [t["tipo"] for t in (await client.get(url, headers=h["e"])).json()] == [
        "hito"
    ]
    finished = (await client.get(f"{url}?estado=cumplido", headers=h["e"])).json()
    assert [t["referencia_id"] for t in finished] == [commitment_id]
    assert (await client.get(f"{url}?estado=raro", headers=h["e"])).status_code == 422


async def test_cu20_progreso_derivado_de_hitos_y_avances(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, *_ = await _world(client, make_user, login)
    url = f"{API}/mentoring/ventures/me/progress-summary"
    empty = (await client.get(url, headers=h["e"])).json()
    assert empty["porcentaje"] == 0 and empty["hitos_total"] == 0

    # sin hitos manda el ultimo porcentaje de avance reportado
    await client.post(
        f"{API}/mentoring/progress",
        json={"observaciones": "Arranque", "porcentaje_avance": 30},
        headers=h["e"],
    )
    assert (await client.get(url, headers=h["e"])).json()["porcentaje"] == 30

    ids = []
    for title in ("Prototipo", "Primera venta", "Local"):
        r = await client.post(
            f"{API}/ventures/{vid}/milestones", json={"titulo": title}, headers=h["e"]
        )
        ids.append(r.json()["hito_id"])
    await client.patch(
        f"{API}/milestones/{ids[0]}", json={"estado": "cumplido"}, headers=h["e"]
    )
    summary = (await client.get(url, headers=h["e"])).json()
    assert (summary["hitos_total"], summary["hitos_cumplidos"]) == (3, 1)
    assert summary["porcentaje"] == 33 and float(summary["ultimo_avance"]) == 30.0
    staff = await client.get(
        f"{API}/mentoring/ventures/{vid}/progress-summary", headers=h["coord"]
    )
    assert staff.json()["porcentaje"] == 33
