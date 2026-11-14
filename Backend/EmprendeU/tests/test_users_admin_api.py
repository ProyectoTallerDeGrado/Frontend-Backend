"""Administracion de usuarios, roles y permisos (requiere permisos)."""

from httpx import AsyncClient

from tests.conftest import MakeUser

API = "/api/v1"


async def test_endpoints_de_administracion_exigen_permiso(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    assert (await client.get(f"{API}/users")).status_code == 401

    await make_user(email="emp@test.com")
    headers = await login("emp@test.com")
    response = await client.get(f"{API}/users", headers=headers)
    assert response.status_code == 403
    body = response.json()["error"]
    assert body["code"] == "forbidden"
    assert body["details"] == {"requerido": "usuarios:consulta"}


async def test_listado_con_busqueda_filtro_y_paginacion(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(
        rol="administrador", email="admin@test.com", nombre="Jhonny", apellido="Roca"
    )
    await make_user(email="e1@test.com", nombre="Camila", apellido="Justiniano")
    await make_user(email="e2@test.com", nombre="Rodrigo", apellido="Anez")
    await make_user(
        rol="asesor", email="m@test.com", nombre="Marcelo", apellido="Cuellar"
    )
    headers = await login("admin@test.com")

    todos = (await client.get(f"{API}/users", headers=headers)).json()
    assert todos["total"] == 4
    assert set(todos) == {"items", "page", "page_size", "total"}

    emp = (await client.get(f"{API}/users?rol=emprendedor", headers=headers)).json()
    assert emp["total"] == 2

    busqueda = (await client.get(f"{API}/users?q=camila justi", headers=headers)).json()
    assert [u["email"] for u in busqueda["items"]] == ["e1@test.com"]

    pagina = (
        await client.get(f"{API}/users?page=2&page_size=3", headers=headers)
    ).json()
    assert len(pagina["items"]) == 1 and pagina["total"] == 4

    assert (await client.get(f"{API}/users?page=0", headers=headers)).status_code == 422


async def test_admin_crea_usuario_con_clave_temporal(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    headers = await login("admin@test.com")

    created = await client.post(
        f"{API}/users",
        json={
            "nombre_completo": "Luis Gutierrez Moreno",
            "email": "luis@test.com",
            "rol": "asesor",
        },
        headers=headers,
    )
    assert created.status_code == 201
    body = created.json()
    assert body["rol"] == "asesor"
    temporary = body["temporary_password"]
    assert temporary

    ok = await client.post(
        f"{API}/auth/login", json={"email": "luis@test.com", "password": temporary}
    )
    assert ok.status_code == 200

    bad_role = await client.post(
        f"{API}/users",
        json={
            "nombre_completo": "Otra Persona",
            "email": "o@test.com",
            "rol": "inexistente",
        },
        headers=headers,
    )
    assert bad_role.status_code == 404
    assert bad_role.json()["error"]["code"] == "role_not_found"


async def test_no_puedes_deshabilitarte_a_ti_mismo(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    admin = await make_user(rol="administrador", email="admin@test.com")
    headers = await login("admin@test.com")
    response = await client.patch(
        f"{API}/users/{admin.usuario_id}/estado",
        json={"estado": "deshabilitada"},
        headers=headers,
    )
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "cannot_disable_self"

    missing = await client.patch(
        f"{API}/users/999999/estado", json={"estado": "habilitada"}, headers=headers
    )
    assert missing.status_code == 404


async def test_roles_y_matriz_de_permisos(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(email="emp@test.com")
    headers = await login("admin@test.com")

    roles = (await client.get(f"{API}/roles", headers=headers)).json()
    by_name = {r["nombre"]: r for r in roles}
    assert set(by_name) == {"administrador", "coordinador", "asesor", "emprendedor"}
    assert by_name["emprendedor"]["total_usuarios"] == 1

    asesor_id = by_name["asesor"]["rol_id"]
    matrix = (
        await client.get(f"{API}/roles/{asesor_id}/permissions", headers=headers)
    ).json()
    assert matrix["permisos"]["asesorias"] == ["consulta", "registro", "modificacion"]
    assert matrix["permisos"]["usuarios"] == []

    nueva = {
        "permisos": {"asesorias": ["consulta"], "reportes": ["consulta", "registro"]}
    }
    saved = await client.put(
        f"{API}/roles/{asesor_id}/permissions", json=nueva, headers=headers
    )
    assert saved.status_code == 200
    assert saved.json()["permisos"]["asesorias"] == ["consulta"]
    assert saved.json()["permisos"]["reportes"] == ["consulta", "registro"]
    assert saved.json()["permisos"]["seguimiento"] == []


async def test_matriz_rechaza_permisos_desconocidos_y_bloqueo_del_admin(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    headers = await login("admin@test.com")
    roles = {
        r["nombre"]: r
        for r in (await client.get(f"{API}/roles", headers=headers)).json()
    }

    unknown = await client.put(
        f"{API}/roles/{roles['asesor']['rol_id']}/permissions",
        json={"permisos": {"inventado": ["consulta"]}},
        headers=headers,
    )
    assert unknown.status_code == 422
    assert unknown.json()["error"]["code"] == "invalid_permissions"

    lockout = await client.put(
        f"{API}/roles/{roles['administrador']['rol_id']}/permissions",
        json={"permisos": {"usuarios": ["consulta"]}},
        headers=headers,
    )
    assert lockout.status_code == 409
    assert lockout.json()["error"]["code"] == "admin_lockout"

    only_admin_can = await client.put(
        f"{API}/roles/999999/permissions", json={"permisos": {}}, headers=headers
    )
    assert only_admin_can.status_code == 404


async def test_admin_no_puede_perder_usuarios_consulta(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    headers = await login("admin@test.com")
    roles = {
        r["nombre"]: r
        for r in (await client.get(f"{API}/roles", headers=headers)).json()
    }
    response = await client.put(
        f"{API}/roles/{roles['administrador']['rol_id']}/permissions",
        json={"permisos": {"usuarios": ["administrativo"]}},
        headers=headers,
    )
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "admin_lockout"


async def test_crud_de_roles_personalizados(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    headers = await login("admin@test.com")
    roles = {
        r["nombre"]: r
        for r in (await client.get(f"{API}/roles", headers=headers)).json()
    }

    created = await client.post(
        f"{API}/roles",
        json={
            "nombre": "Auditor Lectura",
            "descripcion": "Solo consulta",
            "clonar_de": roles["asesor"]["rol_id"],
        },
        headers=headers,
    )
    assert created.status_code == 201, created.text
    body = created.json()
    assert body["nombre"] == "auditor lectura"
    matrix = (
        await client.get(f"{API}/roles/{body['rol_id']}/permissions", headers=headers)
    ).json()
    assert matrix["permisos"]["asesorias"] == ["consulta", "registro", "modificacion"]

    duplicate = await client.post(
        f"{API}/roles", json={"nombre": "auditor lectura"}, headers=headers
    )
    assert duplicate.status_code == 409
    assert duplicate.json()["error"]["code"] == "role_name_taken"

    edited = await client.patch(
        f"{API}/roles/{body['rol_id']}",
        json={"descripcion": "Revisa sin editar"},
        headers=headers,
    )
    assert edited.status_code == 200
    assert edited.json()["descripcion"] == "Revisa sin editar"

    system = await client.delete(
        f"{API}/roles/{roles['asesor']['rol_id']}", headers=headers
    )
    assert system.status_code == 409
    assert system.json()["error"]["code"] == "system_role_protected"

    deleted = await client.delete(f"{API}/roles/{body['rol_id']}", headers=headers)
    assert deleted.status_code == 204
    gone = await client.get(
        f"{API}/roles/{body['rol_id']}/permissions", headers=headers
    )
    assert gone.status_code == 404


async def test_rol_con_usuarios_no_se_elimina_y_rol_solo_lectura_no_escribe(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    headers = await login("admin@test.com")
    created = await client.post(
        f"{API}/roles", json={"nombre": "solo lectura"}, headers=headers
    )
    role_id = created.json()["rol_id"]
    await client.put(
        f"{API}/roles/{role_id}/permissions",
        json={"permisos": {"usuarios": ["consulta"]}},
        headers=headers,
    )
    await make_user(rol="solo lectura", email="lector@test.com")
    in_use = await client.delete(f"{API}/roles/{role_id}", headers=headers)
    assert in_use.status_code == 409
    assert in_use.json()["error"]["code"] == "role_in_use"

    reader = await login("lector@test.com")
    assert (await client.get(f"{API}/users", headers=reader)).status_code == 200
    forbidden = await client.post(
        f"{API}/users",
        json={
            "nombre_completo": "Nuevo Usuario",
            "email": "n@test.com",
            "rol": "asesor",
        },
        headers=reader,
    )
    assert forbidden.status_code == 403
    other = await client.post(
        f"{API}/roles", json={"nombre": "otro rol"}, headers=reader
    )
    assert other.status_code == 403
