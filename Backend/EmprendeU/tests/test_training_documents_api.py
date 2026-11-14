"""Capacitaciones y documentos."""

from pathlib import Path

from httpx import AsyncClient

from tests.conftest import MakeUser

API = "/api/v1"


async def _world(client: AsyncClient, make_user: MakeUser, login):
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(rol="coordinador", email="coord@test.com")
    await make_user(rol="asesor", email="m@test.com")
    await make_user(email="e@test.com")
    await make_user(email="otro@test.com")
    h = {k: await login(f"{k}@test.com") for k in ("admin", "coord", "m", "e", "otro")}
    vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Sabores"}, headers=h["e"])
    ).json()["emprendimiento_id"]
    return h, vid


async def test_capacitaciones_inscripcion_y_asistencia(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, _ = await _world(client, make_user, login)
    assert (
        await client.post(
            f"{API}/training", json={"titulo": "Finanzas"}, headers=h["e"]
        )
    ).status_code == 403
    created = await client.post(
        f"{API}/training",
        json={
            "titulo": "Finanzas basicas",
            "fecha": "2030-05-01T14:00:00Z",
            "modalidad": "virtual",
        },
        headers=h["coord"],
    )
    assert created.status_code == 201
    cid = created.json()["capacitacion_id"]

    enrolled = await client.post(f"{API}/training/{cid}/enroll", headers=h["e"])
    assert enrolled.status_code == 200 and enrolled.json()["total_inscritos"] == 1
    assert (await client.post(f"{API}/training/{cid}/enroll", headers=h["e"])).json()[
        "error"
    ]["code"] == "already_enrolled"
    mine = (await client.get(f"{API}/training/me", headers=h["e"])).json()
    assert len(mine) == 1 and mine[0]["asistencia"] is None
    one = await client.get(f"{API}/training/{cid}", headers=h["e"])
    assert one.status_code == 200 and one.json()["titulo"] == "Finanzas basicas"
    assert (
        await client.get(f"{API}/training/999999", headers=h["e"])
    ).status_code == 404
    assert (await client.get(f"{API}/training/me", headers=h["otro"])).json() == []

    listing = (await client.get(f"{API}/training", headers=h["e"])).json()
    assert listing["total"] == 1 and listing["items"][0]["total_inscritos"] == 1

    people = (
        await client.get(f"{API}/training/{cid}/participants", headers=h["coord"])
    ).json()
    assert people[0]["asistencia"] is None
    eid = people[0]["emprendedor_id"]
    assert (
        await client.get(f"{API}/training/{cid}/participants", headers=h["e"])
    ).status_code == 403
    marked = await client.patch(
        f"{API}/training/{cid}/participants/{eid}",
        json={"asistio": True},
        headers=h["m"],
    )
    assert marked.json()["asistencia"] is True
    mine = (await client.get(f"{API}/training/me", headers=h["e"])).json()
    assert mine[0]["asistencia"] is True
    assert (
        await client.patch(
            f"{API}/training/{cid}/participants/999999",
            json={"asistio": True},
            headers=h["m"],
        )
    ).status_code == 404

    other_eid = (await client.get(f"{API}/entrepreneurs/me", headers=h["otro"])).json()[
        "emprendedor_id"
    ]
    added = await client.post(
        f"{API}/training/{cid}/participants",
        json={"emprendedor_id": other_eid},
        headers=h["coord"],
    )
    assert added.status_code == 201

    await client.patch(
        f"{API}/training/{cid}", json={"estado": "cancelada"}, headers=h["m"]
    )
    late = await client.post(f"{API}/training/{cid}/enroll", headers=h["otro"])
    assert late.status_code in (400, 409)


async def test_documentos_subida_descarga_y_permisos(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid = await _world(client, make_user, login)
    upload = await client.post(
        f"{API}/documents",
        files={
            "file": (
                "../../plan de negocio.pdf",
                b"%PDF-1.4 contenido",
                "application/pdf",
            )
        },
        data={"emprendimiento_id": str(vid)},
        headers=h["e"],
    )
    assert upload.status_code == 201
    doc = upload.json()
    assert doc["nombre"] == "plan de negocio.pdf" and doc["emprendimiento_id"] == vid

    stored = list(Path(__import__("os").environ["UPLOAD_DIR"]).glob("*.pdf"))
    assert len(stored) == 1 and ".." not in stored[0].name

    got = await client.get(
        f"{API}/documents/{doc['documento_id']}/download", headers=h["e"]
    )
    assert got.status_code == 200 and got.content == b"%PDF-1.4 contenido"
    assert (
        await client.get(
            f"{API}/documents/{doc['documento_id']}/download", headers=h["coord"]
        )
    ).status_code == 200
    assert (
        await client.get(
            f"{API}/documents/{doc['documento_id']}/download", headers=h["otro"]
        )
    ).status_code == 403
    assert (
        await client.get(f"{API}/documents?emprendimiento_id={vid}", headers=h["otro"])
    ).status_code == 403
    assert len((await client.get(f"{API}/documents", headers=h["e"])).json()) == 1
    assert (await client.get(f"{API}/documents", headers=h["otro"])).json() == []

    assert (
        await client.delete(f"{API}/documents/{doc['documento_id']}", headers=h["otro"])
    ).status_code == 403
    assert (
        await client.delete(f"{API}/documents/{doc['documento_id']}", headers=h["e"])
    ).status_code == 204
    assert list(Path(__import__("os").environ["UPLOAD_DIR"]).glob("*.pdf")) == []
    assert (
        await client.get(
            f"{API}/documents/{doc['documento_id']}/download", headers=h["e"]
        )
    ).status_code == 404


async def test_documentos_rechaza_tipos_y_tamano(
    client: AsyncClient, make_user: MakeUser, login, monkeypatch
) -> None:
    h, vid = await _world(client, make_user, login)
    bad = await client.post(
        f"{API}/documents",
        files={"file": ("virus.exe", b"MZ", "application/octet-stream")},
        headers=h["e"],
    )
    assert (
        bad.status_code == 415
        and bad.json()["error"]["code"] == "file_type_not_allowed"
    )
    foreign = await client.post(
        f"{API}/documents",
        files={"file": ("a.txt", b"x", "text/plain")},
        data={"emprendimiento_id": str(vid)},
        headers=h["otro"],
    )
    assert foreign.status_code == 403

    from emprendeu.modules.documents import storage

    monkeypatch.setattr(
        storage.LocalStorage,
        "__init__",
        lambda self, root=None, max_mb=None: (
            setattr(
                self, "root", Path(__import__("os").environ["UPLOAD_DIR"]).resolve()
            ),
            setattr(self, "max_bytes", 10),
        )[0],
    )
    big = await client.post(
        f"{API}/documents",
        files={"file": ("grande.txt", b"x" * 100, "text/plain")},
        headers=h["e"],
    )
    assert big.status_code == 413 and big.json()["error"]["code"] == "payload_too_large"
    leftovers = list(Path(__import__("os").environ["UPLOAD_DIR"]).glob("*.txt"))
    assert leftovers == []  # el archivo parcial se elimina
