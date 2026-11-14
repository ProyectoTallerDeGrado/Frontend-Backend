"""Camino de retos, XP, niveles e insignias."""

from httpx import AsyncClient

from tests.conftest import MakeUser

API = "/api/v1"


async def _setup(client: AsyncClient, make_user: MakeUser, login):
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(email="e@test.com")
    admin, emp = await login("admin@test.com"), await login("e@test.com")
    vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Mi idea"}, headers=emp)
    ).json()["emprendimiento_id"]
    return admin, emp, vid


async def test_camino_inicial_y_orden_de_desbloqueo(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    _, emp, vid = await _setup(client, make_user, login)
    journey = (await client.get(f"{API}/journey", headers=emp)).json()
    assert (
        journey["emprendimiento_id"] == vid
        and journey["xp_total"] == 0
        and journey["nivel"] == 1
    )
    states = [r["estado"] for r in journey["retos"]]
    assert states == ["en_curso"] + ["bloqueado"] * 5
    assert [e["estado"] for e in journey["etapas"]] == [
        "en_curso",
        "bloqueada",
        "bloqueada",
    ]

    locked = journey["retos"][3]["reto_id"]
    r = await client.post(f"{API}/journey/challenges/{locked}/complete", headers=emp)
    assert r.status_code == 409 and r.json()["error"]["code"] == "challenge_locked"


async def test_completar_retos_otorga_xp_una_vez_nivel_e_insignias(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    _, emp, _ = await _setup(client, make_user, login)
    retos = (await client.get(f"{API}/journey", headers=emp)).json()["retos"]

    first = await client.post(
        f"{API}/journey/challenges/{retos[0]['reto_id']}/complete", headers=emp
    )
    assert first.status_code == 200
    body = first.json()
    assert body["insignias_nuevas"] == ["Primer paso"]
    assert (
        body["xp_otorgado"] == 50 + 25 and body["xp_total"] == 75 and body["nivel"] == 1
    )

    again = await client.post(
        f"{API}/journey/challenges/{retos[0]['reto_id']}/complete", headers=emp
    )
    assert (
        again.status_code == 409
        and again.json()["error"]["code"] == "challenge_completed"
    )

    for r in retos[1:3]:
        done = await client.post(
            f"{API}/journey/challenges/{r['reto_id']}/complete", headers=emp
        )
        assert done.status_code == 200
    last = done.json()
    assert "Validador" in last["insignias_nuevas"]
    # 50 + 100 + 120 + 25 (primer paso) + 80 (validador) = 375
    assert last["xp_total"] == 375 and last["nivel"] == 2 and last["subio_de_nivel"]

    profile = (await client.get(f"{API}/gamification/me", headers=emp)).json()
    assert profile["xp_total"] == 375 and profile["xp_siguiente_nivel"] == 400
    assert profile["xp_faltante"] == 25
    earned = {b["nombre"] for b in profile["insignias"] if b["obtenida"]}
    assert earned == {"Primer paso", "Validador"}
    assert len(profile["insignias"]) == 6
    assert profile["historial"][0]["cantidad"] in (80, 120)

    journey = (await client.get(f"{API}/journey", headers=emp)).json()
    assert [r["estado"] for r in journey["retos"]][:4] == ["cumplido"] * 3 + [
        "en_curso"
    ]


async def test_catalogo_admin_cambia_xp_y_crea_retos(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    admin, emp, _ = await _setup(client, make_user, login)
    retos = (await client.get(f"{API}/challenges", headers=emp)).json()
    assert len(retos) == 6 and retos[0]["etapa"] == "Preincubación"

    assert (
        await client.patch(
            f"{API}/challenges/{retos[0]['reto_id']}",
            json={"xp_recompensa": 10},
            headers=emp,
        )
    ).status_code == 403
    upd = await client.patch(
        f"{API}/challenges/{retos[0]['reto_id']}",
        json={"xp_recompensa": 60},
        headers=admin,
    )
    assert upd.json()["xp_recompensa"] == 60
    assert (
        await client.patch(
            f"{API}/challenges/{retos[0]['reto_id']}",
            json={"xp_recompensa": -1},
            headers=admin,
        )
    ).status_code == 422

    etapa = retos[0]["etapa_id"]
    new = await client.post(
        f"{API}/challenges",
        json={"titulo": "Reto nuevo", "etapa_id": etapa, "xp_recompensa": 30},
        headers=admin,
    )
    assert new.status_code == 201 and new.json()["orden"] == 7
    bad = await client.post(
        f"{API}/challenges", json={"titulo": "x", "etapa_id": 99999}, headers=admin
    )
    assert bad.status_code == 422 and bad.json()["error"]["code"] == "invalid_stage"

    badges = (await client.get(f"{API}/badges", headers=emp)).json()
    primer = next(b for b in badges if b["nombre"] == "Primer paso")
    patched = await client.patch(
        f"{API}/badges/{primer['insignia_id']}",
        json={"xp_recompensa": 30},
        headers=admin,
    )
    assert patched.json()["xp_recompensa"] == 30

    audit = (await client.get(f"{API}/audit?categoria=config", headers=admin)).json()
    assert {e["accion"] for e in audit["items"]} >= {"config.reto", "config.insignia"}


async def test_personal_ve_camino_ajeno_y_emprendedor_ajeno_no(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    _, _, vid = await _setup(client, make_user, login)
    await make_user(rol="coordinador", email="c@test.com")
    await make_user(email="otro@test.com")
    coord, other = await login("c@test.com"), await login("otro@test.com")
    assert (
        await client.get(f"{API}/journey?emprendimiento_id={vid}", headers=coord)
    ).status_code == 200
    assert (
        await client.get(f"{API}/journey?emprendimiento_id={vid}", headers=other)
    ).status_code == 403
    assert (await client.get(f"{API}/journey", headers=other)).json()["error"][
        "code"
    ] == "no_venture"


async def test_camino_ajeno_incluye_insignias_progreso_e_historial(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    _, emp, vid = await _setup(client, make_user, login)
    await make_user(rol="coordinador", email="c@test.com")
    coord = await login("c@test.com")

    empty = (
        await client.get(f"{API}/journey?emprendimiento_id={vid}", headers=coord)
    ).json()
    assert empty["progreso_pct"] == 0 and empty["xp_siguiente_nivel"] == 200
    assert empty["historial"] == []
    assert not any(b["obtenida"] for b in empty["insignias"])

    retos = (await client.get(f"{API}/journey", headers=emp)).json()["retos"]
    for r in retos[:3]:
        await client.post(
            f"{API}/journey/challenges/{r['reto_id']}/complete", headers=emp
        )

    j = (
        await client.get(f"{API}/journey?emprendimiento_id={vid}", headers=coord)
    ).json()
    assert j["xp_total"] == 375 and j["nivel"] == 2
    assert j["xp_siguiente_nivel"] == 400 and j["xp_faltante"] == 25
    assert j["progreso_pct"] == 87.5  # (375-200)/(400-200)
    assert {b["nombre"] for b in j["insignias"] if b["obtenida"]} == {
        "Primer paso",
        "Validador",
    }
    assert len(j["historial"]) >= 3


async def test_reto_con_evidencia_obligatoria_verifica_criterios(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    """CU07: un reto que exige evidencia rechaza el cumplimiento sin ella."""
    admin, emp, vid = await _setup(client, make_user, login)
    retos = (await client.get(f"{API}/journey", headers=emp)).json()["retos"]
    rid = retos[0]["reto_id"]
    done = f"{API}/journey/challenges/{rid}/complete"
    patch = await client.patch(
        f"{API}/challenges/{rid}",
        json={"requiere_evidencia": True, "criterio_completado": "Sube tu canvas"},
        headers=admin,
    )
    assert patch.status_code == 200 and patch.json()["requiere_evidencia"] is True
    first = (await client.get(f"{API}/journey", headers=emp)).json()["retos"][0]
    assert (
        first["requiere_evidencia"] and first["criterio_completado"] == "Sube tu canvas"
    )

    sin = await client.post(done, headers=emp)
    assert sin.status_code == 422
    assert sin.json()["error"]["code"] == "criteria_not_met"
    corto = await client.post(done, json={"evidencia_texto": "poco"}, headers=emp)
    assert corto.status_code == 422

    ajeno = await client.post(done, json={"documento_id": 999999}, headers=emp)
    assert ajeno.status_code == 422

    ok = await client.post(
        done,
        json={"evidencia_texto": "Entrevisté a 10 clientes potenciales."},
        headers=emp,
    )
    assert ok.status_code == 200 and ok.json()["xp_otorgado"] > 0
    again = await client.post(done, json={"evidencia_texto": "x" * 20}, headers=emp)
    assert again.status_code == 409


async def test_reto_con_evidencia_acepta_documento_del_emprendimiento(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    admin, emp, vid = await _setup(client, make_user, login)
    retos = (await client.get(f"{API}/journey", headers=emp)).json()["retos"]
    rid = retos[0]["reto_id"]
    await client.patch(
        f"{API}/challenges/{rid}", json={"requiere_evidencia": True}, headers=admin
    )
    pdf = {"file": ("canvas.pdf", b"%PDF-1.4 test", "application/pdf")}
    doc = await client.post(
        f"{API}/documents", files=pdf, data={"emprendimiento_id": str(vid)}, headers=emp
    )
    assert doc.status_code == 201
    ok = await client.post(
        f"{API}/journey/challenges/{rid}/complete",
        json={"documento_id": doc.json()["documento_id"]},
        headers=emp,
    )
    assert ok.status_code == 200
    # El directorio de subidas se comparte entre tests: no dejar el archivo.
    deleted = await client.delete(
        f"{API}/documents/{doc.json()['documento_id']}", headers=emp
    )
    assert deleted.status_code == 204
