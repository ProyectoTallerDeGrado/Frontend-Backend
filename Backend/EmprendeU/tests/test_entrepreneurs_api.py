"""Fase 4: alta de emprendedores, emprendimientos propios, progreso y evidencia de hitos."""

import pytest
from httpx import AsyncClient

from emprendeu.modules.entrepreneurs.repository import EntrepreneurRepository
from tests.conftest import MakeUser

API = "/api/v1"


async def _staff(make_user: MakeUser, login):
    await make_user(
        rol="coordinador", email="coord@test.com", nombre="Coco", apellido="Dinador"
    )
    await make_user(
        rol="asesor", email="asesor@test.com", nombre="Aldo", apellido="Asesor"
    )
    return await login("coord@test.com"), await login("asesor@test.com")


async def test_cu04_registrar_emprendedor_documento_unico_y_todo_o_nada(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    coord, asesor = await _staff(make_user, login)
    body = {
        "nombre_completo": "Rosa Quispe",
        "email": "rosa@test.com",
        "documento_identidad": " 1234567 LP ",
    }
    created = await client.post(f"{API}/entrepreneurs", json=body, headers=coord)
    assert created.status_code == 201
    data = created.json()
    assert data["documento_identidad"] == "1234567 LP"  # se limpia
    assert data["email"] == "rosa@test.com" and data["estado"] == "activo"
    assert data["temporary_password"]  # no mando clave: se genera una

    # la clave temporal sirve para entrar y la cuenta es de emprendedor
    login_ok = await client.post(
        f"{API}/auth/login",
        json={"email": "rosa@test.com", "password": data["temporary_password"]},
    )
    assert login_ok.status_code == 200
    me = await client.get(
        f"{API}/auth/me",
        headers={"Authorization": f"Bearer {login_ok.json()['access_token']}"},
    )
    assert me.json()["rol"] == "emprendedor"

    # documento repetido (sin distinguir mayusculas ni espacios): 409 y no crea nada
    dup = await client.post(
        f"{API}/entrepreneurs",
        json={**body, "email": "otra@test.com", "documento_identidad": "1234567  lp"},
        headers=coord,
    )
    assert (
        dup.status_code == 409
        and dup.json()["error"]["code"] == "document_already_registered"
    )
    again = await client.post(
        f"{API}/entrepreneurs",
        json={**body, "email": "otra@test.com", "documento_identidad": "999"},
        headers=coord,
    )
    assert again.status_code == 201  # el correo no quedo ocupado por el intento fallido

    # correo repetido
    same_mail = await client.post(
        f"{API}/entrepreneurs",
        json={**body, "documento_identidad": "5555"},
        headers=coord,
    )
    assert (
        same_mail.status_code == 409
        and same_mail.json()["error"]["code"] == "email_taken"
    )

    # permisos: el asesor y el propio emprendedor no registran
    assert (
        await client.post(
            f"{API}/entrepreneurs",
            json={**body, "email": "x@test.com", "documento_identidad": "1"},
            headers=asesor,
        )
    ).status_code == 403
    emp = {"Authorization": f"Bearer {login_ok.json()['access_token']}"}
    assert (
        await client.post(
            f"{API}/entrepreneurs",
            json={**body, "email": "y@test.com", "documento_identidad": "2"},
            headers=emp,
        )
    ).status_code == 403

    # el documento tambien es unico al editar el perfil propio
    other = await client.patch(
        f"{API}/entrepreneurs/me", json={"documento_identidad": "999"}, headers=emp
    )
    assert other.status_code == 409
    mine = await client.patch(
        f"{API}/entrepreneurs/me",
        json={"documento_identidad": "1234567 LP"},
        headers=emp,
    )
    assert mine.status_code == 200  # el suyo no cuenta como repetido

    listing = (await client.get(f"{API}/entrepreneurs?q=1234567", headers=coord)).json()
    assert listing["total"] == 1
    # la busqueda por documento no distingue mayusculas (documentos con letras: "1234567 LP")
    by_letters = (
        await client.get(f"{API}/entrepreneurs?q=1234567 lp", headers=coord)
    ).json()
    assert by_letters["total"] == 1


async def test_cu05_emprendimiento_propio_y_campos_reservados(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    coord, asesor = await _staff(make_user, login)
    created = (
        await client.post(
            f"{API}/entrepreneurs",
            json={
                "nombre_completo": "Rosa Quispe",
                "email": "rosa@test.com",
                "documento_identidad": "111",
                "password": "clave-rosa-123",
            },
            headers=coord,
        )
    ).json()
    token = (
        await client.post(
            f"{API}/auth/login",
            json={"email": "rosa@test.com", "password": "clave-rosa-123"},
        )
    ).json()["access_token"]
    rosa = {"Authorization": f"Bearer {token}"}
    await make_user(email="otro@test.com", nombre="Otro", apellido="Emprendedor")
    otro = await login("otro@test.com")

    # la coordinacion crea el emprendimiento DE un emprendedor; sin indicarlo, 422
    missing = await client.post(
        f"{API}/ventures", json={"nombre": "Tejidos"}, headers=coord
    )
    assert (
        missing.status_code == 422
        and missing.json()["error"]["code"] == "entrepreneur_required"
    )
    ghost = await client.post(
        f"{API}/ventures",
        json={"nombre": "Tejidos", "emprendedor_id": 99999},
        headers=coord,
    )
    assert ghost.status_code == 422
    made = await client.post(
        f"{API}/ventures",
        json={
            "nombre": "Tejidos",
            "sector": "Textil",
            "emprendedor_id": created["emprendedor_id"],
        },
        headers=coord,
    )
    assert made.status_code == 201
    vid = made.json()["emprendimiento_id"]
    mine = (await client.get(f"{API}/ventures/me", headers=rosa)).json()
    assert [v["emprendimiento_id"] for v in mine] == [vid]  # quedo vinculado a Rosa

    # un emprendedor no crea emprendimientos a nombre de otro
    foreign = await client.post(
        f"{API}/ventures",
        json={"nombre": "Ajeno", "emprendedor_id": created["emprendedor_id"]},
        headers=otro,
    )
    assert foreign.status_code == 403

    # Rosa edita lo suyo, pero no el campo reservado (estado)
    ok = await client.patch(
        f"{API}/ventures/{vid}", json={"descripcion": "Prendas de alpaca"}, headers=rosa
    )
    assert ok.status_code == 200 and ok.json()["descripcion"] == "Prendas de alpaca"
    reserved = await client.patch(
        f"{API}/ventures/{vid}", json={"estado": "cerrado"}, headers=rosa
    )
    assert (
        reserved.status_code == 403
        and reserved.json()["error"]["code"] == "reserved_fields"
    )
    assert reserved.json()["error"]["details"] == {"campos": ["estado"]}
    assert (await client.get(f"{API}/ventures/{vid}", headers=rosa)).json()[
        "estado"
    ] == "activo"

    # otro emprendedor no ve ni edita el emprendimiento ajeno
    assert (await client.get(f"{API}/ventures/{vid}", headers=otro)).status_code == 403
    assert (
        await client.patch(
            f"{API}/ventures/{vid}", json={"nombre": "Robado"}, headers=otro
        )
    ).status_code == 403

    # la coordinacion si cambia el estado
    closed = await client.patch(
        f"{API}/ventures/{vid}", json={"estado": "pausado"}, headers=coord
    )
    assert closed.status_code == 200 and closed.json()["estado"] == "pausado"
    # el asesor solo consulta
    assert (
        await client.get(f"{API}/ventures/{vid}", headers=asesor)
    ).status_code == 200
    assert (
        await client.patch(
            f"{API}/ventures/{vid}", json={"nombre": "x"}, headers=asesor
        )
    ).status_code == 403


async def test_cu06_progreso_visible_para_el_personal_y_cu07_cu08_del_emprendedor(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    coord, asesor = await _staff(make_user, login)
    await make_user(email="e@test.com", nombre="Elena", apellido="Emp")
    emp = await login("e@test.com")
    vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Mi idea"}, headers=emp)
    ).json()["emprendimiento_id"]

    # CU06: el personal ve el camino de CUALQUIER emprendimiento; otro emprendedor, no
    for who in (coord, asesor):
        journey = await client.get(
            f"{API}/journey?emprendimiento_id={vid}", headers=who
        )
        assert journey.status_code == 200
        body = journey.json()
        assert body["emprendimiento_id"] == vid and body["xp_total"] == 0
        assert [e["estado"] for e in body["etapas"]][0] == "en_curso"
        assert body["retos"][0]["estado"] == "en_curso"
    await make_user(email="e2@test.com", nombre="Otra", apellido="Emp")
    other = await login("e2@test.com")
    assert (
        await client.get(f"{API}/journey?emprendimiento_id={vid}", headers=other)
    ).status_code == 403

    # CU07: cumplir un reto otorga XP una sola vez
    first = (await client.get(f"{API}/journey", headers=emp)).json()["retos"][0][
        "reto_id"
    ]
    done = await client.post(f"{API}/journey/challenges/{first}/complete", headers=emp)
    assert done.status_code == 200 and done.json()["xp_otorgado"] > 0
    again = await client.post(f"{API}/journey/challenges/{first}/complete", headers=emp)
    assert (
        again.status_code == 409
        and again.json()["error"]["code"] == "challenge_completed"
    )
    # el personal no cumple retos por el emprendedor
    assert (
        await client.post(
            f"{API}/journey/challenges/{first}/complete?emprendimiento_id={vid}",
            headers=coord,
        )
    ).status_code == 403

    # CU08: XP total e insignias
    profile = (await client.get(f"{API}/gamification/me", headers=emp)).json()
    assert profile["xp_total"] == done.json()["xp_total"] and profile["xp_total"] > 0
    assert (
        await client.get(f"{API}/journey?emprendimiento_id={vid}", headers=coord)
    ).json()["xp_total"] == profile["xp_total"]


async def test_cu20_hito_con_evidencia(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    coord, _ = await _staff(make_user, login)
    await make_user(email="e@test.com", nombre="Elena", apellido="Emp")
    await make_user(email="e2@test.com", nombre="Otra", apellido="Emp")
    emp, other = await login("e@test.com"), await login("e2@test.com")
    vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Mi idea"}, headers=emp)
    ).json()["emprendimiento_id"]
    vid2 = (
        await client.post(f"{API}/ventures", json={"nombre": "Ajena"}, headers=other)
    ).json()["emprendimiento_id"]
    hito = (
        await client.post(
            f"{API}/ventures/{vid}/milestones",
            json={"titulo": "Primer prototipo", "descripcion": "Listo"},
            headers=emp,
        )
    ).json()
    hito2 = (
        await client.post(
            f"{API}/ventures/{vid2}/milestones", json={"titulo": "Otro"}, headers=other
        )
    ).json()

    pdf = {"file": ("prototipo.pdf", b"%PDF-1.4 evidencia", "application/pdf")}
    up = await client.post(
        f"{API}/documents",
        files=pdf,
        data={"emprendimiento_id": str(vid), "hito_id": str(hito["hito_id"])},
        headers=emp,
    )
    assert up.status_code == 201 and up.json()["hito_id"] == hito["hito_id"]

    # el hito debe ser del mismo emprendimiento y exigir emprendimiento
    bad = await client.post(
        f"{API}/documents",
        files=pdf,
        data={"emprendimiento_id": str(vid), "hito_id": str(hito2["hito_id"])},
        headers=emp,
    )
    assert (
        bad.status_code == 422 and bad.json()["error"]["code"] == "milestone_mismatch"
    )
    no_venture = await client.post(
        f"{API}/documents",
        files=pdf,
        data={"hito_id": str(hito["hito_id"])},
        headers=emp,
    )
    assert no_venture.status_code == 422

    # evidencia sin hito sigue funcionando y el listado filtra por hito
    await client.post(
        f"{API}/documents", files=pdf, data={"emprendimiento_id": str(vid)}, headers=emp
    )
    only = (
        await client.get(
            f"{API}/documents?emprendimiento_id={vid}&hito_id={hito['hito_id']}",
            headers=emp,
        )
    ).json()
    assert [d["documento_id"] for d in only] == [up.json()["documento_id"]]
    assert (
        len(
            (
                await client.get(
                    f"{API}/documents?emprendimiento_id={vid}", headers=coord
                )
            ).json()
        )
        == 2
    )
    assert (
        await client.get(f"{API}/documents?emprendimiento_id={vid}", headers=other)
    ).status_code == 403

    # limpieza: la carpeta de subidas es compartida con otras pruebas
    for doc in (
        await client.get(f"{API}/documents?emprendimiento_id={vid}", headers=emp)
    ).json():
        assert (
            await client.delete(f"{API}/documents/{doc['documento_id']}", headers=emp)
        ).status_code == 204


async def test_la_base_impide_documentos_repetidos_aunque_el_servicio_no_lo_vea(
    client: AsyncClient, make_user: MakeUser, login, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Dos altas simultaneas pasan la comprobacion del servicio: el indice unico las frena."""
    coord, _ = await _staff(make_user, login)
    base = {
        "nombre_completo": "Ana Uno",
        "email": "uno@test.com",
        "documento_identidad": "ABC-123",
    }
    assert (
        await client.post(f"{API}/entrepreneurs", json=base, headers=coord)
    ).status_code == 201

    async def never(*args, **kwargs):
        return False

    # el servicio "no ve" el duplicado, como en una carrera entre dos peticiones
    monkeypatch.setattr(EntrepreneurRepository, "document_in_use", never)
    dup = await client.post(
        f"{API}/entrepreneurs",
        json={
            **base,
            "nombre_completo": "Ana Dos",
            "email": "dos@test.com",
            "documento_identidad": "abc-123",
        },
        headers=coord,
    )
    assert (
        dup.status_code == 409
        and dup.json()["error"]["code"] == "document_already_registered"
    )
    monkeypatch.undo()
    # y no quedo nada a medias: ni usuario ni perfil de la segunda
    assert (
        await client.get(f"{API}/entrepreneurs?q=dos@test.com", headers=coord)
    ).json()["total"] == 0
    # los emprendedores sin documento no chocan entre si
    await make_user(email="sin1@test.com")
    await make_user(email="sin2@test.com")
    assert (
        await client.get(f"{API}/entrepreneurs?page_size=50", headers=coord)
    ).json()["total"] >= 3
