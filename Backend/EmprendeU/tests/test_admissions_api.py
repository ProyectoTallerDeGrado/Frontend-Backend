"""CU26: admision al programa."""

from httpx import AsyncClient

from tests.conftest import PASSWORD, MakeUser

API = "/api/v1"


def _application(**over) -> dict:
    body = {
        "nombre": "Lucia",
        "apellido": "Fernandez Rojas",
        "email": "lucia@correo.com",
        "telefono": "70000000",
        "documento_identidad": "9988776 LP",
        "nombre_emprendimiento": "EcoEmpaques",
        "descripcion_emprendimiento": "Empaques compostables",
        "sector": "Sostenibilidad",
    }
    body.update(over)
    return body


async def _staff(make_user: MakeUser, login):
    await make_user(rol="coordinador", email="coord@test.com")
    await make_user(rol="asesor", email="ase@test.com")
    await make_user(email="emp@test.com")
    return {k: await login(f"{k}@test.com") for k in ("coord", "ase", "emp")}


async def test_postulacion_publica_y_listado_solo_personal(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h = await _staff(make_user, login)
    sent = await client.post(f"{API}/admissions", json=_application())
    assert sent.status_code == 201
    assert sent.json() == {
        "postulacion_id": sent.json()["postulacion_id"],
        "estado": "pendiente",
    }

    twin = await client.post(
        f"{API}/admissions", json=_application(email="LUCIA@correo.com")
    )
    assert twin.status_code == 409
    assert twin.json()["error"]["code"] == "application_pending"
    bad = await client.post(
        f"{API}/admissions", json=_application(email="no-es-correo")
    )
    assert bad.status_code == 422

    assert (await client.get(f"{API}/admissions")).status_code == 401
    assert (await client.get(f"{API}/admissions", headers=h["emp"])).status_code == 403
    listed = (
        await client.get(f"{API}/admissions?estado=pendiente", headers=h["coord"])
    ).json()
    assert listed["total"] == 1
    assert listed["items"][0]["nombre_emprendimiento"] == "EcoEmpaques"
    detail = await client.get(
        f"{API}/admissions/{sent.json()['postulacion_id']}", headers=h["coord"]
    )
    assert detail.json()["email"] == "lucia@correo.com"
    assert (
        await client.get(f"{API}/admissions/999999", headers=h["coord"])
    ).status_code == 404


async def test_limite_de_postulaciones_por_ip(client: AsyncClient) -> None:
    for i in range(5):
        r = await client.post(
            f"{API}/admissions", json=_application(email=f"p{i}@correo.com")
        )
        assert r.status_code == 201
    blocked = await client.post(
        f"{API}/admissions", json=_application(email="p9@correo.com")
    )
    assert blocked.status_code == 429
    assert blocked.json()["error"]["code"] == "rate_limited"


async def test_admitir_crea_cuenta_emprendimiento_y_es_definitivo(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h = await _staff(make_user, login)
    pid = (await client.post(f"{API}/admissions", json=_application())).json()[
        "postulacion_id"
    ]
    url = f"{API}/admissions/{pid}/decision"

    # el asesor no decide; el emprendedor tampoco
    assert (
        await client.post(url, json={"decision": "admitida"}, headers=h["ase"])
    ).status_code == 403
    assert (
        await client.post(url, json={"decision": "admitida"}, headers=h["emp"])
    ).status_code == 403

    admitted = await client.post(
        url,
        json={"decision": "admitida", "observaciones": "Buen perfil"},
        headers=h["coord"],
    )
    assert admitted.status_code == 200, admitted.text
    body = admitted.json()
    assert (
        body["estado"] == "admitida"
        and body["fecha_decision"]
        and body["decidido_por_id"]
    )
    assert body["emprendedor_id"] and body["emprendimiento_id"]
    temp = body["temporary_password"]
    assert temp and len(temp) >= 8

    # la cuenta creada inicia sesion con la clave temporal y ve su emprendimiento
    login_r = await client.post(
        f"{API}/auth/login", json={"email": "lucia@correo.com", "password": temp}
    )
    assert login_r.status_code == 200
    token = {"Authorization": f"Bearer {login_r.json()['access_token']}"}
    mine = (await client.get(f"{API}/ventures/me", headers=token)).json()
    assert [v["nombre"] for v in mine] == ["EcoEmpaques"]
    assert mine[0]["etapa_actual"] is not None

    # decision definitiva: no se puede cambiar ni repetir
    again = await client.post(
        url, json={"decision": "rechazada", "observaciones": "x"}, headers=h["coord"]
    )
    assert again.status_code == 409
    assert again.json()["error"]["code"] == "decision_final"

    audit_actions = {
        e["accion"]
        for e in (
            await client.get(
                f"{API}/audit?page_size=50", headers=await _admin(make_user, login)
            )
        ).json()["items"]
    }
    assert "negocio.postulacion" in audit_actions
    _ = PASSWORD


async def _admin(make_user: MakeUser, login):
    await make_user(rol="administrador", email="root@test.com")
    return await login("root@test.com")


async def test_rechazar_pendiente_y_datos_insuficientes(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h = await _staff(make_user, login)
    pid = (await client.post(f"{API}/admissions", json=_application())).json()[
        "postulacion_id"
    ]
    url = f"{API}/admissions/{pid}/decision"

    no_reason = await client.post(
        url, json={"decision": "rechazada"}, headers=h["coord"]
    )
    assert no_reason.status_code == 422
    assert no_reason.json()["error"]["code"] == "admission_incomplete"

    hold = await client.post(
        url,
        json={"decision": "pendiente", "observaciones": "Falta ampliar el modelo"},
        headers=h["coord"],
    )
    assert hold.status_code == 200
    assert (
        hold.json()["estado"] == "pendiente" and hold.json()["fecha_decision"] is None
    )
    assert hold.json()["observaciones_decision"] == "Falta ampliar el modelo"

    rejected = await client.post(
        url,
        json={"decision": "rechazada", "observaciones": "No cumple el perfil"},
        headers=h["coord"],
    )
    assert rejected.status_code == 200 and rejected.json()["estado"] == "rechazada"
    assert rejected.json()["emprendedor_id"] is None
    assert (
        await client.post(url, json={"decision": "admitida"}, headers=h["coord"])
    ).status_code == 409

    # sin documento no se puede admitir
    other = (
        await client.post(
            f"{API}/admissions",
            json=_application(email="sin@doc.com", documento_identidad=None),
        )
    ).json()["postulacion_id"]
    incomplete = await client.post(
        f"{API}/admissions/{other}/decision",
        json={"decision": "admitida"},
        headers=h["coord"],
    )
    assert incomplete.status_code == 422
    assert incomplete.json()["error"]["details"] == {"faltan": ["documento_identidad"]}


async def test_admitir_con_correo_ya_registrado_no_deja_nada_a_medias(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h = await _staff(make_user, login)
    await make_user(email="lucia@correo.com")  # el correo ya tiene cuenta
    pid = (await client.post(f"{API}/admissions", json=_application())).json()[
        "postulacion_id"
    ]

    failed = await client.post(
        f"{API}/admissions/{pid}/decision",
        json={"decision": "admitida"},
        headers=h["coord"],
    )
    assert failed.status_code == 409
    still = (await client.get(f"{API}/admissions/{pid}", headers=h["coord"])).json()
    assert still["estado"] == "pendiente" and still["emprendimiento_id"] is None
    assert (
        await client.get(f"{API}/ventures?q=EcoEmpaques", headers=h["coord"])
    ).json()["total"] == 0


async def test_si_falla_el_emprendimiento_tambien_se_deshace_la_cuenta(
    client: AsyncClient, make_user: MakeUser, login, monkeypatch
) -> None:
    from emprendeu.core.errors import DomainError
    from emprendeu.modules.ventures import VentureService

    h = await _staff(make_user, login)
    pid = (await client.post(f"{API}/admissions", json=_application())).json()[
        "postulacion_id"
    ]

    async def boom(self, *args, **kwargs):
        raise DomainError("fallo simulado")

    monkeypatch.setattr(VentureService, "create", boom)
    failed = await client.post(
        f"{API}/admissions/{pid}/decision",
        json={"decision": "admitida"},
        headers=h["coord"],
    )
    assert failed.status_code == 400

    # la cuenta creada antes del fallo no quedo: el correo sigue libre y la postulacion pendiente
    users = await client.get(f"{API}/users?q=lucia@correo.com", headers=h["coord"])
    if users.status_code == 200:
        assert users.json()["total"] == 0
    still = (await client.get(f"{API}/admissions/{pid}", headers=h["coord"])).json()
    assert still["estado"] == "pendiente"
    monkeypatch.undo()
    ok = await client.post(
        f"{API}/admissions/{pid}/decision",
        json={"decision": "admitida"},
        headers=h["coord"],
    )
    assert ok.status_code == 200
