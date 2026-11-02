"""CU26: postulaciones (formulario publico) y admision de punta a punta."""

import pytest
from httpx import AsyncClient

from emprendeu.modules.entrepreneurs import EntrepreneurService
from tests.conftest import MakeUser

API = "/api/v1"

FORM = {
    "nombre": "Rosa María",
    "apellido": "Quispe Mamani",
    "email": "rosa@correo.com",
    "telefono": "70012345",
    "documento_identidad": "7654321 SC",
    "nombre_emprendimiento": "Tejidos Andinos",
    "descripcion_emprendimiento": "Prendas de alpaca",
    "sector": "Textil",
}


async def _staff(make_user: MakeUser, login):
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(
        rol="coordinador", email="coord@test.com", nombre="Coco", apellido="Dinador"
    )
    await make_user(rol="asesor", email="asesor@test.com")
    await make_user(email="emp@test.com")
    return {
        k: await login(f"{k}@test.com") for k in ("admin", "coord", "asesor", "emp")
    }


async def _apply(client: AsyncClient, **overrides) -> dict:
    r = await client.post(f"{API}/applications", json={**FORM, **overrides})
    assert r.status_code == 201, r.text
    return r.json()


async def _pending_id(client: AsyncClient, headers, email: str = FORM["email"]) -> int:
    items = (
        await client.get(
            f"{API}/applications?estado=pendiente&q={email}", headers=headers
        )
    ).json()["items"]
    assert len(items) == 1
    return items[0]["postulacion_id"]


async def test_formulario_publico_validacion_y_permisos_de_la_lista(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h = await _staff(make_user, login)
    # sin iniciar sesion se puede postular, y la respuesta no revela nada interno
    assert await _apply(client) == {"recibida": True}
    # pero revisar es del personal
    assert (await client.get(f"{API}/applications")).status_code == 401
    assert (
        await client.get(f"{API}/applications", headers=h["emp"])
    ).status_code == 403
    listing = await client.get(f"{API}/applications", headers=h["asesor"])
    assert listing.status_code == 200 and listing.json()["total"] == 1
    first = listing.json()["items"][0]
    assert first["estado"] == "pendiente" and first["email"] == "rosa@correo.com"
    assert first["emprendedor_id"] is None and first["decidido_por"] is None

    # datos invalidos
    assert (
        await client.post(f"{API}/applications", json={**FORM, "email": "no-es-correo"})
    ).status_code == 422
    assert (
        await client.post(f"{API}/applications", json={**FORM, "nombre": "  "})
    ).status_code == 422
    sin_emprendimiento = {k: v for k, v in FORM.items() if k != "nombre_emprendimiento"}
    assert (
        await client.post(f"{API}/applications", json=sin_emprendimiento)
    ).status_code == 422


async def test_antispam_campo_trampa_correo_pendiente_y_limite_de_intentos(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h = await _staff(make_user, login)
    # un bot llena el campo trampa: parece exito pero no se guarda nada
    bot = await client.post(
        f"{API}/applications",
        json={**FORM, "email": "bot@x.com", "sitio_web": "http://spam"},
    )
    assert bot.status_code == 201
    assert (await client.get(f"{API}/applications", headers=h["coord"])).json()[
        "total"
    ] == 0

    await _apply(client)
    dup = await client.post(
        f"{API}/applications", json={**FORM, "email": "ROSA@correo.com"}
    )
    assert (
        dup.status_code == 409 and dup.json()["error"]["code"] == "application_pending"
    )

    # tras rechazarla, la misma persona puede volver a postular
    pid = await _pending_id(client, h["coord"])
    rej = await client.post(
        f"{API}/applications/{pid}/reject",
        json={"observaciones": "Sin cupo"},
        headers=h["coord"],
    )
    assert rej.status_code == 200
    assert (await client.post(f"{API}/applications", json=FORM)).status_code == 201

    # limite de intentos por conexion (5 por hora; ya van 4 contando bot, dup y las dos validas)
    codes = [
        (
            await client.post(
                f"{API}/applications", json={**FORM, "email": f"x{i}@correo.com"}
            )
        ).status_code
        for i in range(3)
    ]
    assert codes == [201, 429, 429]


async def test_admitir_crea_usuario_emprendedor_y_emprendimiento_y_entra_a_la_app(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h = await _staff(make_user, login)
    await _apply(client)
    pid = await _pending_id(client, h["coord"])

    # solo coordinacion decide: el asesor consulta pero no admite
    assert (
        await client.post(
            f"{API}/applications/{pid}/admit", json={}, headers=h["asesor"]
        )
    ).status_code == 403

    r = await client.post(
        f"{API}/applications/{pid}/admit",
        json={"observaciones": "Buen perfil"},
        headers=h["coord"],
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert (
        body["estado"] == "admitida" and body["observaciones_decision"] == "Buen perfil"
    )
    assert body["decidido_por"] == "Coco Dinador" and body["fecha_decision"]
    assert body["emprendedor_id"] and body["emprendimiento_id"]
    temporary = body["temporary_password"]
    assert temporary

    # el emprendedor ya existe con los nombres tal como los escribio, y su documento
    entrepreneur = (
        await client.get(
            f"{API}/entrepreneurs/{body['emprendedor_id']}", headers=h["coord"]
        )
    ).json()
    assert (entrepreneur["nombre"], entrepreneur["apellido"]) == (
        "Rosa María",
        "Quispe Mamani",
    )
    assert (
        entrepreneur["documento_identidad"] == "7654321 SC"
        and entrepreneur["estado"] == "activo"
    )

    # aparece en la app: puede entrar con la clave temporal y ve su emprendimiento en la primera etapa
    session = await client.post(
        f"{API}/auth/login", json={"email": "rosa@correo.com", "password": temporary}
    )
    assert session.status_code == 200
    rosa = {"Authorization": f"Bearer {session.json()['access_token']}"}
    assert (await client.get(f"{API}/auth/me", headers=rosa)).json()[
        "rol"
    ] == "emprendedor"
    mine = (await client.get(f"{API}/ventures/me", headers=rosa)).json()
    assert [v["emprendimiento_id"] for v in mine] == [body["emprendimiento_id"]]
    assert mine[0]["nombre"] == "Tejidos Andinos" and mine[0]["sector"] == "Textil"
    assert mine[0]["estado"] == "activo" and mine[0]["etapa_actual"] is not None
    journey = await client.get(f"{API}/journey", headers=rosa)
    assert (
        journey.status_code == 200
        and journey.json()["retos"][0]["estado"] == "en_curso"
    )

    # la lista la muestra como admitida y la auditoria lo registra
    admitted = (
        await client.get(f"{API}/applications?estado=admitida", headers=h["coord"])
    ).json()
    assert admitted["total"] == 1
    audit = (await client.get(f"{API}/audit?page_size=20", headers=h["admin"])).json()[
        "items"
    ]
    assert any(
        "postulación" in json_text(a).lower() or "postulacion" in json_text(a).lower()
        for a in audit
    )


def json_text(value: object) -> str:
    return str(value)


async def test_una_decision_no_se_puede_cambiar(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h = await _staff(make_user, login)
    await _apply(client)
    await _apply(
        client,
        email="beto@correo.com",
        nombre="Beto",
        apellido="Rojas",
        documento_identidad="111",
    )
    admitted_id = await _pending_id(client, h["coord"])
    rejected_id = await _pending_id(client, h["coord"], "beto@correo.com")
    await client.post(
        f"{API}/applications/{admitted_id}/admit", json={}, headers=h["coord"]
    )
    # rechazar exige explicar el motivo
    empty = await client.post(
        f"{API}/applications/{rejected_id}/reject",
        json={"observaciones": "  "},
        headers=h["coord"],
    )
    assert empty.status_code == 422
    rej = await client.post(
        f"{API}/applications/{rejected_id}/reject",
        json={"observaciones": "No cumple el perfil"},
        headers=h["coord"],
    )
    assert rej.status_code == 200
    assert (
        rej.json()["estado"] == "rechazada"
        and rej.json()["observaciones_decision"] == "No cumple el perfil"
    )
    assert (
        rej.json()["emprendedor_id"] is None
        and rej.json()["decidido_por"] == "Coco Dinador"
    )

    for pid in (admitted_id, rejected_id):
        for action, body in (("admit", {}), ("reject", {"observaciones": "otra vez"})):
            r = await client.post(
                f"{API}/applications/{pid}/{action}", json=body, headers=h["coord"]
            )
            assert (
                r.status_code == 409
                and r.json()["error"]["code"] == "application_decided"
            ), (pid, action)
    # un rechazo no creo nada
    assert (
        await client.get(f"{API}/users?q=beto@correo.com", headers=h["admin"])
    ).json()["total"] == 0
    assert (
        await client.post(
            f"{API}/applications/99999/admit", json={}, headers=h["coord"]
        )
    ).status_code == 404


async def test_admision_con_conflicto_no_crea_nada_y_sigue_pendiente(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h = await _staff(make_user, login)
    # ya existe una cuenta con ese correo
    await make_user(email="rosa@correo.com", nombre="Otra", apellido="Persona")
    await _apply(client)
    pid = await _pending_id(client, h["coord"])
    taken = await client.post(
        f"{API}/applications/{pid}/admit", json={}, headers=h["coord"]
    )
    assert taken.status_code == 409 and taken.json()["error"]["code"] == "email_taken"

    # otra persona ya registro ese documento de identidad
    created = await client.post(
        f"{API}/entrepreneurs",
        json={
            "nombre_completo": "Dueno Previo",
            "email": "previo@correo.com",
            "documento_identidad": "7654321 sc",
        },
        headers=h["coord"],
    )
    assert created.status_code == 201
    await _apply(client, email="otro@correo.com", nombre="Otro", apellido="Aspirante")
    pid2 = await _pending_id(client, h["coord"], "otro@correo.com")
    doc = await client.post(
        f"{API}/applications/{pid2}/admit", json={}, headers=h["coord"]
    )
    assert (
        doc.status_code == 409
        and doc.json()["error"]["code"] == "document_already_registered"
    )

    for pid_ in (pid, pid2):
        got = (
            await client.get(f"{API}/applications/{pid_}", headers=h["coord"])
        ).json()
        assert got["estado"] == "pendiente" and got["emprendedor_id"] is None
    assert (await client.get(f"{API}/ventures?q=Tejidos", headers=h["coord"])).json()[
        "total"
    ] == 0


async def test_admision_es_todo_o_nada_si_falla_a_mitad(
    client: AsyncClient, make_user: MakeUser, login, monkeypatch: pytest.MonkeyPatch
) -> None:
    h = await _staff(make_user, login)
    await _apply(client)
    pid = await _pending_id(client, h["coord"])

    async def boom(*args, **kwargs):
        raise RuntimeError("falla simulada despues de crear usuario y emprendimiento")

    monkeypatch.setattr(EntrepreneurService, "mark_admitted", boom)
    with pytest.raises(RuntimeError):
        await client.post(
            f"{API}/applications/{pid}/admit", json={}, headers=h["coord"]
        )
    monkeypatch.undo()

    # ni usuario, ni emprendedor, ni emprendimiento: la postulacion sigue pendiente
    assert (
        await client.get(f"{API}/users?q=rosa@correo.com", headers=h["admin"])
    ).json()["total"] == 0
    assert (
        await client.get(f"{API}/entrepreneurs?q=7654321", headers=h["coord"])
    ).json()["total"] == 0
    assert (await client.get(f"{API}/ventures?q=Tejidos", headers=h["coord"])).json()[
        "total"
    ] == 0
    got = (await client.get(f"{API}/applications/{pid}", headers=h["coord"])).json()
    assert got["estado"] == "pendiente"
    # y se puede volver a admitir despues
    retry = await client.post(
        f"{API}/applications/{pid}/admit", json={}, headers=h["coord"]
    )
    assert retry.status_code == 200 and retry.json()["temporary_password"]
