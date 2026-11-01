"""Auditoria, emprendedores y emprendimientos."""

from httpx import AsyncClient

from tests.conftest import PASSWORD, MakeUser

API = "/api/v1"


async def test_login_y_cambios_quedan_en_auditoria(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(
        rol="administrador", email="admin@test.com", nombre="Jhonny", apellido="Roca"
    )
    victim = await make_user(email="v@test.com")
    bad = await client.post(
        f"{API}/auth/login", json={"email": "v@test.com", "password": "mala-clave"}
    )
    assert bad.status_code == 401
    headers = await login("admin@test.com")
    await client.patch(
        f"{API}/users/{victim.usuario_id}/estado",
        json={"estado": "deshabilitada"},
        headers=headers,
    )

    audit = (await client.get(f"{API}/audit", headers=headers)).json()
    codes = [(e["accion"], e["resultado"]) for e in audit["items"]]
    assert ("usuarios.deshabilitar", "exitoso") in codes
    assert ("accesos.login", "exitoso") in codes
    assert ("accesos.login_fallido", "rechazado") in codes
    top = audit["items"][0]
    assert top["actor"] == "Jhonny Roca" and top["categoria"] == "usuarios"

    only_access = (
        await client.get(f"{API}/audit?categoria=accesos", headers=headers)
    ).json()
    assert {e["categoria"] for e in only_access["items"]} == {"accesos"}
    rejected = (
        await client.get(f"{API}/audit?resultado=rechazado", headers=headers)
    ).json()
    assert rejected["total"] == 1

    csv = await client.get(f"{API}/audit/export", headers=headers)
    assert csv.status_code == 200
    assert csv.headers["content-type"].startswith("text/csv")
    assert "Deshabilitó cuenta" in csv.text


async def test_auditoria_exige_permiso(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(email="e@test.com")
    headers = await login("e@test.com")
    assert (await client.get(f"{API}/audit", headers=headers)).status_code == 403


async def test_bloqueo_por_intentos_de_login(
    client: AsyncClient, make_user: MakeUser
) -> None:
    await make_user(email="a@test.com")
    for _ in range(5):
        r = await client.post(
            f"{API}/auth/login", json={"email": "a@test.com", "password": "x"}
        )
        assert r.status_code == 401
    blocked = await client.post(
        f"{API}/auth/login", json={"email": "a@test.com", "password": PASSWORD}
    )
    assert blocked.status_code == 429
    assert blocked.json()["error"]["code"] == "rate_limited"
    assert int(blocked.headers["Retry-After"]) > 0


async def test_emprendedor_crea_su_emprendimiento_y_ve_su_etapa(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(email="e@test.com")
    headers = await login("e@test.com")

    created = await client.post(
        f"{API}/ventures",
        json={"nombre": "Sabores del Oriente", "sector": "Alimentos"},
        headers=headers,
    )
    assert created.status_code == 201
    body = created.json()
    assert body["etapa_actual"]["nombre"] == "Preincubación"
    vid = body["emprendimiento_id"]

    mine = (await client.get(f"{API}/ventures/me", headers=headers)).json()
    assert [v["emprendimiento_id"] for v in mine] == [vid]
    me = (await client.get(f"{API}/entrepreneurs/me", headers=headers)).json()
    assert me["emprendimientos"][0]["emprendimiento_id"] == vid

    patched = await client.patch(
        f"{API}/ventures/{vid}",
        json={"descripcion": "Comida regional"},
        headers=headers,
    )
    assert patched.json()["descripcion"] == "Comida regional"

    # otro emprendedor no tiene acceso
    await make_user(email="otro@test.com")
    other = await login("otro@test.com")
    assert (await client.get(f"{API}/ventures/{vid}", headers=other)).status_code == 403
    assert (await client.get(f"{API}/ventures", headers=other)).status_code == 403


async def test_cambio_de_etapa_hitos_y_necesidades(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(rol="coordinador", email="coord@test.com")
    await make_user(email="e@test.com")
    admin, coord, emp = (
        await login("admin@test.com"),
        await login("coord@test.com"),
        await login("e@test.com"),
    )
    vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Mi idea"}, headers=emp)
    ).json()["emprendimiento_id"]

    stages = (await client.get(f"{API}/stages", headers=emp)).json()
    by_name = {s["nombre"]: s for s in stages}
    assert [s["orden"] for s in stages] == [1, 2, 3, 4]

    # un emprendedor no cambia su propia etapa (seguimiento:modificacion)
    denied = await client.put(
        f"{API}/ventures/{vid}/stage",
        json={"etapa_id": by_name["Incubación"]["etapa_id"]},
        headers=emp,
    )
    assert denied.status_code == 403
    changed = await client.put(
        f"{API}/ventures/{vid}/stage",
        json={"etapa_id": by_name["Incubación"]["etapa_id"]},
        headers=coord,
    )
    assert changed.json()["etapa_actual"]["nombre"] == "Incubación"
    history = (await client.get(f"{API}/ventures/{vid}/stages", headers=emp)).json()
    assert [h["estado"] for h in history] == ["completada", "activa"]

    # etapa inactiva no se puede asignar
    await client.patch(
        f"{API}/stages/{by_name['Crecimiento']['etapa_id']}",
        json={"estado": "inactiva"},
        headers=admin,
    )
    inactive = await client.put(
        f"{API}/ventures/{vid}/stage",
        json={"etapa_id": by_name["Crecimiento"]["etapa_id"]},
        headers=coord,
    )
    assert inactive.status_code == 409

    hito = await client.post(
        f"{API}/ventures/{vid}/milestones",
        json={"titulo": "Primer prototipo"},
        headers=emp,
    )
    assert hito.status_code == 201
    done = await client.patch(
        f"{API}/milestones/{hito.json()['hito_id']}",
        json={"estado": "cumplido"},
        headers=emp,
    )
    assert done.json()["fecha_cumplimiento"] is not None

    need = (
        await client.post(
            f"{API}/needs", json={"nombre": "Financiamiento"}, headers=admin
        )
    ).json()
    added = await client.post(
        f"{API}/ventures/{vid}/needs",
        json={"necesidad_id": need["necesidad_id"], "prioridad": "alta"},
        headers=emp,
    )
    assert added.json()["necesidad"] == "Financiamiento"
    resolved = await client.patch(
        f"{API}/venture-needs/{added.json()['emprendimiento_necesidad_id']}/resolve",
        headers=emp,
    )
    assert resolved.json()["estado"] == "resuelta"

    listing = (await client.get(f"{API}/ventures?q=idea", headers=coord)).json()
    assert (
        listing["total"] == 1
        and listing["items"][0]["etapa_actual"]["nombre"] == "Incubación"
    )
    people = (await client.get(f"{API}/entrepreneurs?q=ana", headers=coord)).json()
    assert people["total"] == 1
