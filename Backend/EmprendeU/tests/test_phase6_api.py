"""Fase 6: capacitaciones (CU27 a CU29), documentos del asesor (CU30) y necesidades (CU24)."""

from httpx import AsyncClient

from tests.conftest import MakeUser

API = "/api/v1"
FUTURE = "2030-05-01T14:00:00Z"


async def _world(client: AsyncClient, make_user: MakeUser, login):
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(rol="coordinador", email="coord@test.com")
    await make_user(
        rol="asesor", email="m@test.com", nombre="Marcelo", apellido="Cuellar"
    )
    await make_user(rol="asesor", email="m2@test.com", nombre="Otro", apellido="Asesor")
    await make_user(email="e@test.com", nombre="Elena", apellido="Rojas")
    await make_user(email="otro@test.com", nombre="Omar", apellido="Vega")
    h = {
        k: await login(f"{k}@test.com")
        for k in ("admin", "coord", "m", "m2", "e", "otro")
    }
    vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Sabores"}, headers=h["e"])
    ).json()["emprendimiento_id"]
    return h, vid


async def _training(client: AsyncClient, headers, **extra) -> dict:
    r = await client.post(
        f"{API}/training",
        json={"titulo": "Finanzas", "fecha": FUTURE, **extra},
        headers=headers,
    )
    assert r.status_code == 201, r.text
    return r.json()


async def _publish(client: AsyncClient, headers, cid: int) -> None:
    r = await client.patch(
        f"{API}/training/{cid}", json={"estado": "publicada"}, headers=headers
    )
    assert r.status_code == 200, r.text


async def test_cu27_crear_editar_y_publicar_una_capacitacion(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    # solo coordinacion: ni el asesor ni el emprendedor crean
    for who in ("m", "e"):
        r = await client.post(f"{API}/training", json={"titulo": "X"}, headers=h[who])
        assert r.status_code == 403, who

    created = (
        await client.post(
            f"{API}/training", json={"titulo": "Marketing"}, headers=h["coord"]
        )
    ).json()
    cid = created["capacitacion_id"]
    assert created["estado"] == "borrador" and created["fecha"] is None
    # editar
    edited = await client.patch(
        f"{API}/training/{cid}",
        json={
            "titulo": "Marketing digital",
            "descripcion": "Redes sociales",
            "modalidad": "virtual",
        },
        headers=h["coord"],
    )
    assert (
        edited.json()["titulo"] == "Marketing digital"
        and edited.json()["descripcion"] == "Redes sociales"
    )
    # publicar exige fecha
    no_date = await client.patch(
        f"{API}/training/{cid}", json={"estado": "publicada"}, headers=h["coord"]
    )
    assert (
        no_date.status_code == 422
        and no_date.json()["error"]["code"] == "date_required"
    )
    ok = await client.patch(
        f"{API}/training/{cid}",
        json={"estado": "publicada", "fecha": FUTURE},
        headers=h["coord"],
    )
    assert ok.json()["estado"] == "publicada"
    # el asesor consulta pero no edita ni publica
    assert (
        await client.patch(
            f"{API}/training/{cid}", json={"titulo": "Y"}, headers=h["m"]
        )
    ).status_code == 403
    # no se vuelve a borrador; al terminar ya no se edita
    back = await client.patch(
        f"{API}/training/{cid}", json={"estado": "borrador"}, headers=h["coord"]
    )
    assert (
        back.status_code == 409
        and back.json()["error"]["code"] == "invalid_training_transition"
    )
    await client.patch(
        f"{API}/training/{cid}", json={"estado": "realizada"}, headers=h["coord"]
    )
    closed = await client.patch(
        f"{API}/training/{cid}", json={"titulo": "Z"}, headers=h["coord"]
    )
    assert (
        closed.status_code == 409
        and closed.json()["error"]["code"] == "training_closed"
    )

    # el personal ve los borradores; el emprendedor, no
    await client.post(
        f"{API}/training", json={"titulo": "Borrador oculto"}, headers=h["coord"]
    )
    staff = (await client.get(f"{API}/training", headers=h["m"])).json()
    assert staff["total"] == 2
    emp = (await client.get(f"{API}/training", headers=h["e"])).json()
    assert [t["titulo"] for t in emp["items"]] == ["Marketing digital"]


async def test_cu28_participantes_sin_repetir_y_asistencia(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    cid = (await _training(client, h["coord"]))["capacitacion_id"]
    elena = (await client.get(f"{API}/entrepreneurs/me", headers=h["e"])).json()[
        "emprendedor_id"
    ]
    omar = (await client.get(f"{API}/entrepreneurs/me", headers=h["otro"])).json()[
        "emprendedor_id"
    ]
    url = f"{API}/training/{cid}/participants"

    # un borrador todavia no admite participantes
    assert (
        await client.post(url, json={"emprendedor_id": elena}, headers=h["coord"])
    ).status_code == 409
    await _publish(client, h["coord"], cid)

    added = await client.post(url, json={"emprendedor_id": elena}, headers=h["coord"])
    assert added.status_code == 201
    assert (added.json()["nombre"], added.json()["apellido"]) == ("Elena", "Rojas")
    assert added.json()["email"] == "e@test.com" and added.json()["asistencia"] is None
    # no se repite el participante en la misma capacitacion
    dup = await client.post(url, json={"emprendedor_id": elena}, headers=h["coord"])
    assert dup.status_code == 409 and dup.json()["error"]["code"] == "already_enrolled"
    assert (
        await client.post(url, json={"emprendedor_id": 99999}, headers=h["coord"])
    ).status_code == 404
    await client.post(url, json={"emprendedor_id": omar}, headers=h["coord"])

    # el asesor ve la lista (con nombres) pero no registra ni marca
    people = (await client.get(url, headers=h["m"])).json()
    assert sorted(p["nombre"] for p in people) == ["Elena", "Omar"]
    assert (
        await client.post(url, json={"emprendedor_id": omar}, headers=h["m"])
    ).status_code == 403
    mark = f"{url}/{elena}"
    assert (
        await client.patch(mark, json={"asistio": True}, headers=h["m"])
    ).status_code == 403
    assert (await client.get(url, headers=h["e"])).status_code == 403

    assert (
        await client.patch(mark, json={"asistio": True}, headers=h["coord"])
    ).json()["asistencia"] is True
    assert (
        await client.patch(mark, json={"asistio": False}, headers=h["coord"])
    ).json()["asistencia"] is False
    assert (
        await client.patch(f"{url}/99999", json={"asistio": True}, headers=h["coord"])
    ).status_code == 404
    # una capacitacion cancelada ya no recibe cambios de asistencia
    await client.patch(
        f"{API}/training/{cid}", json={"estado": "cancelada"}, headers=h["coord"]
    )
    late = await client.patch(mark, json={"asistio": True}, headers=h["coord"])
    assert (
        late.status_code == 409 and late.json()["error"]["code"] == "training_not_open"
    )


async def test_cu29_el_emprendedor_ve_las_publicadas_y_su_propia_asistencia(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    visible = (await _training(client, h["coord"], titulo="Finanzas"))[
        "capacitacion_id"
    ]
    await _training(client, h["coord"], titulo="Borrador")  # sin publicar
    cancelled = (await _training(client, h["coord"], titulo="Cancelada"))[
        "capacitacion_id"
    ]
    await _publish(client, h["coord"], visible)
    await _publish(client, h["coord"], cancelled)
    await client.patch(
        f"{API}/training/{cancelled}", json={"estado": "cancelada"}, headers=h["coord"]
    )
    elena = (await client.get(f"{API}/entrepreneurs/me", headers=h["e"])).json()[
        "emprendedor_id"
    ]

    first = (await client.get(f"{API}/training/published", headers=h["e"])).json()
    assert [t["titulo"] for t in first] == ["Finanzas"]  # ni borradores ni canceladas
    assert first[0]["inscrito"] is False and first[0]["mi_asistencia"] is None

    # se inscribe sola, y la coordinacion marca su asistencia
    assert (
        await client.post(f"{API}/training/{visible}/enroll", headers=h["e"])
    ).status_code == 200
    mine = (await client.get(f"{API}/training/published", headers=h["e"])).json()[0]
    assert (
        mine["inscrito"] is True
        and mine["mi_asistencia"] is None
        and mine["total_inscritos"] == 1
    )
    await client.patch(
        f"{API}/training/{visible}/participants/{elena}",
        json={"asistio": True},
        headers=h["coord"],
    )
    mine = (await client.get(f"{API}/training/published", headers=h["e"])).json()[0]
    assert mine["mi_asistencia"] is True
    assert (await client.get(f"{API}/training/me", headers=h["e"])).json()[0][
        "mi_asistencia"
    ] is True
    # otra persona ve la misma capacitacion pero no la asistencia de Elena
    other = (await client.get(f"{API}/training/published", headers=h["otro"])).json()[0]
    assert (
        other["inscrito"] is False
        and other["mi_asistencia"] is None
        and other["total_inscritos"] == 1
    )
    # el personal no usa esta vista
    assert (
        await client.get(f"{API}/training/published", headers=h["coord"])
    ).json() == []


async def test_cu30_documentos_coordinacion_asesor_asignado_y_emprendedor(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid = await _world(client, make_user, login)
    advisor = (await client.get(f"{API}/auth/me", headers=h["m"])).json()["usuario_id"]
    await client.put(
        f"{API}/mentoring/mentors/{advisor}/enabled",
        json={"habilitado": True},
        headers=h["coord"],
    )
    assert (
        await client.post(
            f"{API}/mentoring/assignments",
            json={"usuario_id": advisor, "emprendimiento_id": vid},
            headers=h["coord"],
        )
    ).status_code == 201

    def upload(headers, name: str = "plan.pdf"):
        return client.post(
            f"{API}/documents",
            files={"file": (name, b"%PDF-1.4 contenido", "application/pdf")},
            data={"emprendimiento_id": str(vid)},
            headers=headers,
        )

    by_advisor = await upload(h["m"], "del-asesor.pdf")
    assert by_advisor.status_code == 201  # el asesor asignado sube
    by_coord = await upload(h["coord"], "de-coordinacion.pdf")
    assert by_coord.status_code == 201
    assert (
        await upload(h["m2"], "intruso.pdf")
    ).status_code == 403  # asesor sin asignacion
    assert (await upload(h["otro"], "ajeno.pdf")).status_code == 403  # otro emprendedor
    mine = await upload(h["e"], "del-emprendedor.pdf")
    assert mine.status_code == 201

    # cada quien ve lo suyo: el emprendedor, solo los de su emprendimiento
    own = (await client.get(f"{API}/documents", headers=h["e"])).json()
    assert len(own) == 3 and all(d["emprendimiento_id"] == vid for d in own)
    assert (await client.get(f"{API}/documents", headers=h["otro"])).json() == []
    assert (
        await client.get(f"{API}/documents?emprendimiento_id={vid}", headers=h["otro"])
    ).status_code == 403

    # descargar
    doc_id = by_coord.json()["documento_id"]
    for who in ("m", "e", "coord"):
        got = await client.get(f"{API}/documents/{doc_id}/download", headers=h[who])
        assert got.status_code == 200 and got.content.startswith(b"%PDF"), who
    assert (
        await client.get(f"{API}/documents/{doc_id}/download", headers=h["otro"])
    ).status_code == 403

    # eliminar: el asesor asignado y la coordinacion si; otro asesor y otro emprendedor, no
    assert (
        await client.delete(f"{API}/documents/{doc_id}", headers=h["m2"])
    ).status_code == 403
    assert (
        await client.delete(f"{API}/documents/{doc_id}", headers=h["otro"])
    ).status_code == 403
    assert (
        await client.delete(
            f"{API}/documents/{by_advisor.json()['documento_id']}", headers=h["m"]
        )
    ).status_code == 204
    assert (
        await client.delete(
            f"{API}/documents/{mine.json()['documento_id']}", headers=h["coord"]
        )
    ).status_code == 204
    assert (
        await client.delete(f"{API}/documents/{doc_id}", headers=h["coord"])
    ).status_code == 204
    assert (
        await client.get(f"{API}/documents/{doc_id}/download", headers=h["coord"])
    ).status_code == 404
    assert (await client.get(f"{API}/documents", headers=h["e"])).json() == []


async def test_cu24_registrar_necesidades_nuevas_o_del_catalogo(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid = await _world(client, make_user, login)
    url = f"{API}/ventures/{vid}/needs"

    # el catalogo solo lo ve; el emprendedor no puede crear necesidades sueltas...
    assert (
        await client.post(f"{API}/needs", json={"nombre": "X"}, headers=h["e"])
    ).status_code == 403
    # ...pero al registrar la suya puede nombrar una nueva y se crea en el catalogo
    new = await client.post(
        url,
        json={
            "nombre": "Capital de trabajo",
            "descripcion": "Para comprar materia prima",
            "prioridad": "alta",
        },
        headers=h["e"],
    )
    assert new.status_code == 201, new.text
    assert (
        new.json()["necesidad"] == "Capital de trabajo"
        and new.json()["prioridad"] == "alta"
    )
    assert new.json()["estado"] == "detectada"
    catalog = (await client.get(f"{API}/needs", headers=h["e"])).json()
    assert [n["nombre"] for n in catalog] == ["Capital de trabajo"]
    assert catalog[0]["descripcion"] == "Para comprar materia prima"

    # la misma necesidad aun sin resolver no se repite (sin distinguir mayusculas)
    dup = await client.post(url, json={"nombre": "CAPITAL DE TRABAJO"}, headers=h["e"])
    assert dup.status_code == 409 and dup.json()["error"]["code"] == "need_exists"
    # otra necesidad existente se elige por id, y otra persona reutiliza el mismo catalogo
    other_vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Otra"}, headers=h["otro"])
    ).json()["emprendimiento_id"]
    reuse = await client.post(
        f"{API}/ventures/{other_vid}/needs",
        json={"nombre": "capital de trabajo"},
        headers=h["otro"],
    )
    assert reuse.status_code == 201
    assert (
        len((await client.get(f"{API}/needs", headers=h["e"])).json()) == 1
    )  # no se duplico
    by_id = await client.post(
        url, json={"necesidad_id": catalog[0]["necesidad_id"]}, headers=h["e"]
    )
    assert by_id.status_code == 409

    # resuelta y vuelve a aparecer: se reabre (la base no repite el par)
    row_id = new.json()["emprendimiento_necesidad_id"]
    assert (
        await client.patch(f"{API}/venture-needs/{row_id}/resolve", headers=h["e"])
    ).json()["estado"] == "resuelta"
    reopened = await client.post(
        url, json={"nombre": "Capital de trabajo", "prioridad": "media"}, headers=h["e"]
    )
    assert reopened.status_code == 201
    assert (
        reopened.json()["estado"] == "detectada"
        and reopened.json()["prioridad"] == "media"
    )
    assert reopened.json()["fecha_resuelta"] is None
    assert len((await client.get(url, headers=h["e"])).json()) == 1

    # validaciones y alcance
    both = await client.post(
        url, json={"nombre": "A", "necesidad_id": 1}, headers=h["e"]
    )
    assert both.status_code == 422
    assert (await client.post(url, json={}, headers=h["e"])).status_code == 422
    assert (
        await client.post(url, json={"necesidad_id": 99999}, headers=h["e"])
    ).status_code == 404
    assert (
        await client.post(url, json={"nombre": "Ajeno"}, headers=h["otro"])
    ).status_code == 403


async def test_get_capacitacion_oculta_los_borradores_al_emprendedor(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    draft = (await _training(client, h["coord"]))["capacitacion_id"]
    assert (await client.get(f"{API}/training/{draft}", headers=h["m"])).json()[
        "estado"
    ] == "borrador"
    assert (
        await client.get(f"{API}/training/{draft}", headers=h["e"])
    ).status_code == 404
    await _publish(client, h["coord"], draft)
    assert (await client.get(f"{API}/training/{draft}", headers=h["e"])).json()[
        "titulo"
    ] == "Finanzas"
    # no se confunde con /published ni con /me
    assert (
        await client.get(f"{API}/training/published", headers=h["e"])
    ).status_code == 200
    assert (
        await client.get(f"{API}/training/99999", headers=h["m"])
    ).status_code == 404


async def test_limite_de_postulaciones_usa_la_ip_reenviada_solo_si_se_configura(
    client: AsyncClient, monkeypatch
) -> None:
    from emprendeu.core.config import get_settings
    from emprendeu.modules.entrepreneurs.dependencies import get_application_limiter

    form = {"nombre": "Ana", "apellido": "Rios", "nombre_emprendimiento": "Idea"}

    async def send(i: int, ip: str):
        r = await client.post(
            f"{API}/applications",
            json={**form, "email": f"a{i}@c.com"},
            headers={"x-forwarded-for": ip},
        )
        return r.status_code

    # sin confiar en la cabecera, todas comparten la IP del servidor web: se agota a la 6ta
    monkeypatch.setattr(get_settings(), "application_trust_forwarded_for", False)
    assert [await send(i, f"10.0.0.{i}") for i in range(6)] == [201] * 5 + [429]

    # confiando en ella, cada IP real tiene su propio cupo
    get_application_limiter().reset()
    monkeypatch.setattr(get_settings(), "application_trust_forwarded_for", True)
    assert [await send(100 + i, f"10.0.1.{i}, 192.168.0.1") for i in range(6)] == [
        201
    ] * 6
    # y una misma IP real sigue limitada
    assert [await send(200 + i, "10.9.9.9") for i in range(6)] == [201] * 5 + [429]
