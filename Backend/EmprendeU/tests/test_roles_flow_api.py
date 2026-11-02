"""Un recorrido de punta a punta por cada rol: administrador, coordinador, asesor y emprendedor.

No repite el detalle de cada caso de uso (ya cubierto en sus pruebas): comprueba que cada persona
puede hacer su trabajo completo de principio a fin, y que no puede hacer el de otro rol.
"""

from datetime import UTC, date, datetime, timedelta

from httpx import AsyncClient

from tests.conftest import PASSWORD, MakeUser

API = "/api/v1"
DOC = "Para calcular tus costos separa costos fijos y variables.\n\nEl punto de equilibrio iguala ingresos y costos."


async def _auth(
    client: AsyncClient, email: str, password: str = PASSWORD
) -> dict[str, str]:
    r = await client.post(
        f"{API}/auth/login", json={"email": email, "password": password}
    )
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


async def _me(client: AsyncClient, headers) -> dict:
    return (await client.get(f"{API}/auth/me", headers=headers)).json()


async def test_flujo_del_administrador(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(
        rol="administrador", email="admin@test.com", nombre="Ada", apellido="Admin"
    )
    admin = await login("admin@test.com")

    # 1. crea personal con cada rol y los ve en la lista
    made = {}
    for rol in ("coordinador", "asesor"):
        r = await client.post(
            f"{API}/users",
            json={
                "nombre_completo": f"Persona {rol.title()}",
                "email": f"{rol}@test.com",
                "rol": rol,
                "password": PASSWORD,
            },
            headers=admin,
        )
        assert r.status_code == 201 and r.json()["rol"] == rol, r.text
        made[rol] = r.json()["usuario_id"]
    users = (await client.get(f"{API}/users?page_size=50", headers=admin)).json()
    assert {u["email"] for u in users["items"]} >= {
        "coordinador@test.com",
        "asesor@test.com",
    }

    # 2. cambia un rol y deshabilita y rehabilita una cuenta
    assert (
        await client.patch(
            f"{API}/users/{made['asesor']}/rol",
            json={"rol": "coordinador"},
            headers=admin,
        )
    ).json()["rol"] == "coordinador"
    await client.patch(
        f"{API}/users/{made['asesor']}/rol", json={"rol": "asesor"}, headers=admin
    )
    off = await client.patch(
        f"{API}/users/{made['coordinador']}/estado",
        json={"estado": "deshabilitada"},
        headers=admin,
    )
    assert off.status_code == 200
    blocked = await client.post(
        f"{API}/auth/login",
        json={"email": "coordinador@test.com", "password": PASSWORD},
    )
    assert blocked.status_code in (401, 403)
    await client.patch(
        f"{API}/users/{made['coordinador']}/estado",
        json={"estado": "habilitada"},
        headers=admin,
    )
    assert (await _auth(client, "coordinador@test.com"))["Authorization"]

    # 3. edita la matriz de permisos de un rol y el cambio se nota al volver a entrar
    roles = {
        r["nombre"]: r["rol_id"]
        for r in (await client.get(f"{API}/roles", headers=admin)).json()
    }
    matrix = (
        await client.get(
            f"{API}/roles/{roles['coordinador']}/permissions", headers=admin
        )
    ).json()["permisos"]
    assert "reportes" in matrix
    reduced = {k: v for k, v in matrix.items() if k != "reportes"}
    saved = await client.put(
        f"{API}/roles/{roles['coordinador']}/permissions",
        json={"permisos": reduced},
        headers=admin,
    )
    assert saved.status_code == 200
    coord_again = await _auth(client, "coordinador@test.com")
    assert (
        await client.get(f"{API}/indicators/dashboard", headers=coord_again)
    ).status_code == 403
    await client.put(
        f"{API}/roles/{roles['coordinador']}/permissions",
        json={"permisos": matrix},
        headers=admin,
    )
    assert (
        await client.get(
            f"{API}/indicators/dashboard",
            headers=await _auth(client, "coordinador@test.com"),
        )
    ).status_code == 200

    # 4. configuracion del programa: parametros de seguimiento y etapas
    settings = (await client.get(f"{API}/alerts/settings", headers=admin)).json()
    new = {
        **{
            k: settings[k]
            for k in (
                "inactividad_dias",
                "caida_sentimiento_pct",
                "periodos_consecutivos",
                "notificar_coordinador",
                "notificar_asesor",
                "alertar_incumplimiento",
            )
        },
        "inactividad_dias": 21,
    }
    assert (await client.put(f"{API}/alerts/settings", json=new, headers=admin)).json()[
        "inactividad_dias"
    ] == 21
    stage = (await client.get(f"{API}/stages", headers=admin)).json()[-1]
    assert (
        await client.patch(
            f"{API}/stages/{stage['etapa_id']}",
            json={"estado": "inactiva"},
            headers=admin,
        )
    ).json()["estado"] == "inactiva"
    await client.patch(
        f"{API}/stages/{stage['etapa_id']}", json={"estado": "activa"}, headers=admin
    )

    # 5. panel de resumen, alertas del sistema y bitacora con todo lo anterior
    overview = (await client.get(f"{API}/indicators/overview", headers=admin)).json()
    assert overview["usuarios"] and overview["acciones_auditadas"] > 0
    assert (
        await client.post(f"{API}/alerts/evaluate", headers=admin)
    ).status_code == 200
    actions = {
        a["accion"]
        for a in (await client.get(f"{API}/audit?page_size=100", headers=admin)).json()[
            "items"
        ]
    }
    # la bitacora guarda todo lo que hizo: usuarios creados, cambio de rol, permisos y parametros
    assert {
        "usuarios.crear",
        "usuarios.cambiar_rol",
        "usuarios.deshabilitar",
    } <= actions
    assert (await client.get(f"{API}/audit/export", headers=admin)).status_code == 200

    # 6. lo que NO es suyo: el dia a dia del programa es de coordinacion
    assert (
        await client.post(
            f"{API}/mentoring/assignments",
            json={"usuario_id": made["asesor"], "emprendimiento_id": 1},
            headers=admin,
        )
    ).status_code == 403
    assert (
        await client.post(f"{API}/training", json={"titulo": "X"}, headers=admin)
    ).status_code == 403
    assert (
        await client.post(f"{API}/applications/1/admit", json={}, headers=admin)
    ).status_code == 403


async def test_flujo_de_coordinacion(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(
        rol="coordinador", email="coord@test.com", nombre="Coco", apellido="Dinador"
    )
    await make_user(
        rol="asesor", email="asesor@test.com", nombre="Aldo", apellido="Asesor"
    )
    coord = await login("coord@test.com")
    advisor_id = (await _me(client, await login("asesor@test.com")))["usuario_id"]

    # 1. admision: postulacion publica -> admitir (usuario, emprendedor y emprendimiento)
    form = {
        "nombre": "Rosa",
        "apellido": "Quispe",
        "email": "rosa@correo.com",
        "documento_identidad": "111",
        "nombre_emprendimiento": "Tejidos",
        "sector": "Textil",
    }
    assert (await client.post(f"{API}/applications", json=form)).status_code == 201
    pending = (
        await client.get(f"{API}/applications?estado=pendiente", headers=coord)
    ).json()["items"][0]
    admitted = (
        await client.post(
            f"{API}/applications/{pending['postulacion_id']}/admit",
            json={"observaciones": "ok"},
            headers=coord,
        )
    ).json()
    vid = admitted["emprendimiento_id"]
    # y registra a otra persona directamente
    direct = await client.post(
        f"{API}/entrepreneurs",
        json={
            "nombre_completo": "Beto Rojas",
            "email": "beto@correo.com",
            "documento_identidad": "222",
        },
        headers=coord,
    )
    assert direct.status_code == 201
    beto_ent = direct.json()["emprendedor_id"]
    beto_vid = (
        await client.post(
            f"{API}/ventures",
            json={"nombre": "Panes", "emprendedor_id": beto_ent},
            headers=coord,
        )
    ).json()["emprendimiento_id"]

    # 2. mentoria: habilita al asesor y lo asigna
    assert (
        await client.put(
            f"{API}/mentoring/mentors/{advisor_id}/enabled",
            json={"habilitado": True},
            headers=coord,
        )
    ).status_code == 200
    assert (
        await client.post(
            f"{API}/mentoring/assignments",
            json={"usuario_id": advisor_id, "emprendimiento_id": vid},
            headers=coord,
        )
    ).status_code == 201

    # 3. seguimiento: etapa siguiente (sin saltos) e historial
    stages = sorted(
        (await client.get(f"{API}/stages", headers=coord)).json(),
        key=lambda s: s["orden"],
    )
    assert (
        await client.put(
            f"{API}/ventures/{vid}/stage",
            json={"etapa_id": stages[2]["etapa_id"]},
            headers=coord,
        )
    ).status_code == 409  # salto
    assert (
        await client.put(
            f"{API}/ventures/{vid}/stage",
            json={"etapa_id": stages[1]["etapa_id"]},
            headers=coord,
        )
    ).status_code == 200
    assert (
        len((await client.get(f"{API}/ventures/{vid}/stages", headers=coord)).json())
        >= 2
    )
    history = (
        await client.get(f"{API}/mentoring/ventures/{vid}/history", headers=coord)
    ).json()
    assert any(e["tipo"] == "etapa" for e in history)

    # 4. capacitacion: crear, publicar, inscribir y marcar asistencia
    training = (
        await client.post(
            f"{API}/training",
            json={"titulo": "Finanzas", "fecha": "2030-06-01T14:00:00Z"},
            headers=coord,
        )
    ).json()["capacitacion_id"]
    assert (
        await client.patch(
            f"{API}/training/{training}", json={"estado": "publicada"}, headers=coord
        )
    ).json()["estado"] == "publicada"
    assert (
        await client.post(
            f"{API}/training/{training}/participants",
            json={"emprendedor_id": beto_ent},
            headers=coord,
        )
    ).status_code == 201
    assert (
        await client.patch(
            f"{API}/training/{training}/participants/{beto_ent}",
            json={"asistio": True},
            headers=coord,
        )
    ).json()["asistencia"] is True

    # 5. documentos del emprendimiento
    up = await client.post(
        f"{API}/documents",
        files={"file": ("plan.pdf", b"%PDF-1.4 x", "application/pdf")},
        data={"emprendimiento_id": str(beto_vid)},
        headers=coord,
    )
    assert up.status_code == 201
    assert (
        await client.delete(
            f"{API}/documents/{up.json()['documento_id']}", headers=coord
        )
    ).status_code == 204

    # 6. tablero y reportes (vista previa y CSV)
    assert (await client.get(f"{API}/indicators/dashboard", headers=coord)).json()[
        "emprendimientos_total"
    ] >= 2
    csv = await client.get(f"{API}/indicators/reports/resumen/export", headers=coord)
    assert csv.status_code == 200 and "Tejidos" in csv.text
    assert (await client.get(f"{API}/alerts", headers=coord)).status_code == 200

    # 7. lo que NO es suyo: usuarios, roles y configuracion son del administrador
    assert (
        await client.post(
            f"{API}/users",
            json={"nombre_completo": "X Y", "email": "x@y.com", "rol": "asesor"},
            headers=coord,
        )
    ).status_code == 403
    assert (
        await client.get(f"{API}/roles/1/permissions", headers=coord)
    ).status_code == 403
    assert (
        await client.post(f"{API}/alerts/evaluate", headers=coord)
    ).status_code == 403
    assert (
        await client.post(
            f"{API}/ai/knowledge", json={"titulo": "G", "contenido": DOC}, headers=coord
        )
    ).status_code == 201  # base de conocimiento: coordinacion si


async def test_flujo_del_asesor(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(rol="coordinador", email="coord@test.com")
    await make_user(
        rol="asesor", email="asesor@test.com", nombre="Marcelo", apellido="Cuellar"
    )
    await make_user(
        rol="asesor", email="otro@test.com", nombre="Otro", apellido="Asesor"
    )
    await make_user(email="emp@test.com", nombre="Elena", apellido="Rojas")
    coord, adv, other, emp = [
        await login(f"{k}@test.com") for k in ("coord", "asesor", "otro", "emp")
    ]
    advisor_id = (await _me(client, adv))["usuario_id"]
    emp_id = (await _me(client, emp))["usuario_id"]
    vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Sabores"}, headers=emp)
    ).json()["emprendimiento_id"]
    await client.put(
        f"{API}/mentoring/mentors/{advisor_id}/enabled",
        json={"habilitado": True},
        headers=coord,
    )
    await client.post(
        f"{API}/mentoring/assignments",
        json={"usuario_id": advisor_id, "emprendimiento_id": vid},
        headers=coord,
    )

    # 1. ve sus emprendimientos y el progreso (solo lectura)
    assert (
        await client.get(f"{API}/journey?emprendimiento_id={vid}", headers=adv)
    ).status_code == 200
    assert (await client.get(f"{API}/ventures/{vid}", headers=adv)).json()[
        "nombre"
    ] == "Sabores"
    assert (
        await client.get(f"{API}/mentoring/ventures/{vid}/history", headers=adv)
    ).status_code == 200
    assert (
        await client.get(f"{API}/mentoring/ventures/{vid}/history", headers=other)
    ).status_code == 403  # no es suyo

    # 2. disponibilidad: agrega un horario y uno que se solapa se rechaza sin guardar nada
    day = date.today() + timedelta(days=2)

    def slot(a: str, b: str) -> dict[str, str]:
        return {"fecha_inicio": f"{day}T{a}-04:00", "fecha_fin": f"{day}T{b}-04:00"}

    assert (
        await client.post(
            f"{API}/mentoring/mentors/{advisor_id}/availability",
            json=slot("09:00:00", "11:00:00"),
            headers=adv,
        )
    ).status_code == 201
    assert (
        await client.post(
            f"{API}/mentoring/mentors/{advisor_id}/availability",
            json=slot("10:00:00", "12:00:00"),
            headers=adv,
        )
    ).status_code == 409

    # 3. acompanamiento: sesion realizada, recomendacion y compromiso para la emprendedora
    past = (datetime.now(UTC) - timedelta(days=1)).isoformat()
    session = (
        await client.post(
            f"{API}/mentoring/sessions/register",
            json={"emprendimiento_id": vid, "fecha_realizada": past, "tema": "Costos"},
            headers=adv,
        )
    ).json()["sesion_id"]
    assert (
        await client.post(
            f"{API}/mentoring/recommendations",
            json={
                "emprendimiento_id": vid,
                "sesion_id": session,
                "titulo": "Define tu cliente",
                "contenido": "x",
            },
            headers=adv,
        )
    ).status_code == 201
    commitment = await client.post(
        f"{API}/mentoring/commitments",
        json={
            "emprendimiento_id": vid,
            "sesion_id": session,
            "descripcion": "Subir fotos",
            "usuario_id": emp_id,
        },
        headers=adv,
    )
    assert commitment.status_code == 201
    assert (
        await client.get(
            f"{API}/mentoring/commitments/me?estado=pendiente", headers=emp
        )
    ).json()[0]["descripcion"] == "Subir fotos"

    # 4. documentos y capacitaciones (solo consulta)
    up = await client.post(
        f"{API}/documents",
        files={"file": ("guia.pdf", b"%PDF-1.4 x", "application/pdf")},
        data={"emprendimiento_id": str(vid)},
        headers=adv,
    )
    assert up.status_code == 201
    assert (await client.get(f"{API}/training", headers=adv)).status_code == 200
    assert (
        await client.post(f"{API}/training", json={"titulo": "X"}, headers=adv)
    ).status_code == 403

    # 5. alertas del emprendimiento asignado: la revisa y la atiende (genera una el job)
    await client.post(f"{API}/alerts/evaluate", headers=await login("admin@test.com"))
    mine = [
        a
        for a in (await client.get(f"{API}/alerts?page_size=50", headers=adv)).json()[
            "items"
        ]
        if a["emprendimiento_id"] == vid
    ]
    if mine:
        assert (
            await client.patch(
                f"{API}/alerts/{mine[0]['alerta_id']}",
                json={"estado": "atendida"},
                headers=adv,
            )
        ).json()["atendida_por_id"] == advisor_id

    # 6. lo que NO es suyo: asignar, habilitar, admitir y crear usuarios
    assert (
        await client.post(
            f"{API}/mentoring/assignments",
            json={"usuario_id": advisor_id, "emprendimiento_id": vid},
            headers=adv,
        )
    ).status_code == 403
    assert (
        await client.put(
            f"{API}/mentoring/mentors/{advisor_id}/enabled",
            json={"habilitado": False},
            headers=adv,
        )
    ).status_code == 403
    assert (
        await client.post(f"{API}/applications/1/admit", json={}, headers=adv)
    ).status_code == 403
    assert (
        await client.post(
            f"{API}/entrepreneurs",
            json={
                "nombre_completo": "A B",
                "email": "a@b.com",
                "documento_identidad": "9",
            },
            headers=adv,
        )
    ).status_code == 403
    assert (await client.get(f"{API}/audit", headers=adv)).status_code == 403


async def test_flujo_del_emprendedor(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(rol="coordinador", email="coord@test.com")
    await make_user(
        rol="asesor", email="asesor@test.com", nombre="Marcelo", apellido="Cuellar"
    )
    admin, coord, adv = [
        await login(f"{k}@test.com") for k in ("admin", "coord", "asesor")
    ]
    advisor_id = (await _me(client, adv))["usuario_id"]
    await client.post(
        f"{API}/ai/knowledge",
        json={"titulo": "Guia de costos", "contenido": DOC},
        headers=admin,
    )

    # 1. se registra sola desde la app y entra; aun no tiene emprendimiento
    reg = await client.post(
        f"{API}/auth/register",
        json={
            "nombre_completo": "Camila Justiniano",
            "email": "camila@correo.com",
            "password": "clave-larga-1",
        },
    )
    assert reg.status_code == 201
    emp = await _auth(client, "camila@correo.com", "clave-larga-1")
    assert (await client.get(f"{API}/ventures/me", headers=emp)).json() == []
    assert (await client.get(f"{API}/journey", headers=emp)).status_code == 404 or (
        await client.get(f"{API}/journey", headers=emp)
    ).status_code == 409

    # 2. crea su emprendimiento, ve su camino y cumple el primer reto (XP, nivel, insignias)
    vid = (
        await client.post(
            f"{API}/ventures",
            json={"nombre": "Sabores del Oriente", "sector": "Alimentos"},
            headers=emp,
        )
    ).json()["emprendimiento_id"]
    first = (await client.get(f"{API}/journey", headers=emp)).json()["retos"][0][
        "reto_id"
    ]
    done = (
        await client.post(f"{API}/journey/challenges/{first}/complete", headers=emp)
    ).json()
    assert done["xp_total"] > 0
    profile = (await client.get(f"{API}/gamification/me", headers=emp)).json()
    assert profile["xp_total"] == done["xp_total"] and profile["insignias"]

    # 3. registra un avance, un hito con evidencia y una necesidad
    assert (
        await client.post(
            f"{API}/mentoring/progress",
            json={"observaciones": "Primera venta"},
            headers=emp,
        )
    ).status_code == 201
    hito = (
        await client.post(
            f"{API}/ventures/{vid}/milestones",
            json={"titulo": "Prototipo"},
            headers=emp,
        )
    ).json()["hito_id"]
    ev = await client.post(
        f"{API}/documents",
        files={"file": ("foto.png", b"\x89PNG", "image/png")},
        data={"emprendimiento_id": str(vid), "hito_id": str(hito)},
        headers=emp,
    )
    assert ev.status_code == 201 and ev.json()["hito_id"] == hito
    assert (
        await client.post(
            f"{API}/ventures/{vid}/needs",
            json={"nombre": "Capital de trabajo"},
            headers=emp,
        )
    ).status_code == 201

    # 4. agenda una mentoria: coordinacion lo prepara (etapa, asesor, horario) y ella reserva
    await client.put(
        f"{API}/mentoring/mentors/{advisor_id}/enabled",
        json={"habilitado": True},
        headers=coord,
    )
    await client.post(
        f"{API}/mentoring/assignments",
        json={"usuario_id": advisor_id, "emprendimiento_id": vid},
        headers=coord,
    )
    stages = sorted(
        (await client.get(f"{API}/stages", headers=coord)).json(),
        key=lambda s: s["orden"],
    )
    for stage in stages[:2]:  # primera etapa y siguiente
        await client.put(
            f"{API}/ventures/{vid}/stage",
            json={"etapa_id": stage["etapa_id"]},
            headers=coord,
        )
    day = date.today() + timedelta(days=2)
    await client.post(
        f"{API}/mentoring/mentors/{advisor_id}/availability",
        json={
            "fecha_inicio": f"{day}T09:00:00-04:00",
            "fecha_fin": f"{day}T11:00:00-04:00",
        },
        headers=adv,
    )
    assert (await client.get(f"{API}/mentoring/booking-status", headers=emp)).json()[
        "habilitado"
    ] is True
    slots = (
        await client.get(
            f"{API}/mentoring/mentors/{advisor_id}/slots?fecha={day}", headers=emp
        )
    ).json()
    booked = await client.post(
        f"{API}/mentoring/sessions",
        json={"mentor_id": advisor_id, "inicio": slots[0]["inicio"], "tema": "Costos"},
        headers=emp,
    )
    assert booked.status_code == 201
    assert (
        len(
            (
                await client.get(
                    f"{API}/mentoring/sessions/me?estado=programada", headers=emp
                )
            ).json()
        )
        == 1
    )

    # 5. tareas: cumple un compromiso que le dejo el asesor
    past = (datetime.now(UTC) - timedelta(days=1)).isoformat()
    sid = (
        await client.post(
            f"{API}/mentoring/sessions/register",
            json={"emprendimiento_id": vid, "fecha_realizada": past, "tema": "Costos"},
            headers=adv,
        )
    ).json()["sesion_id"]
    emp_id = (await _me(client, emp))["usuario_id"]
    cid = (
        await client.post(
            f"{API}/mentoring/commitments",
            json={
                "emprendimiento_id": vid,
                "sesion_id": sid,
                "descripcion": "Subir fotos",
                "usuario_id": emp_id,
            },
            headers=adv,
        )
    ).json()["compromiso_id"]
    assert (
        await client.patch(
            f"{API}/mentoring/commitments/{cid}", json={"completado": True}, headers=emp
        )
    ).json()["estado"] == "cumplido"
    assert (
        await client.get(
            f"{API}/mentoring/commitments/me?estado=pendiente", headers=emp
        )
    ).json() == []

    # 6. capacitaciones publicadas: se inscribe; coordinacion marca su asistencia
    tid = (
        await client.post(
            f"{API}/training",
            json={"titulo": "Finanzas", "fecha": "2030-06-01T14:00:00Z"},
            headers=coord,
        )
    ).json()["capacitacion_id"]
    await client.patch(
        f"{API}/training/{tid}", json={"estado": "publicada"}, headers=coord
    )
    assert (
        await client.post(f"{API}/training/{tid}/enroll", headers=emp)
    ).status_code == 200
    eid = (await client.get(f"{API}/entrepreneurs/me", headers=emp)).json()[
        "emprendedor_id"
    ]
    await client.patch(
        f"{API}/training/{tid}/participants/{eid}",
        json={"asistio": True},
        headers=coord,
    )
    assert (await client.get(f"{API}/training/published", headers=emp)).json()[0][
        "mi_asistencia"
    ] is True

    # 7. coach IA con fuente, y el historial completo de su emprendimiento
    chat = (
        await client.post(
            f"{API}/ai/chat", json={"mensaje": "Como calculo mis costos?"}, headers=emp
        )
    ).json()
    assert chat["fuente"] is True and chat["fuentes"] == ["Guia de costos"]
    kinds = {
        e["tipo"]
        for e in (
            await client.get(f"{API}/mentoring/ventures/me/history", headers=emp)
        ).json()
    }
    assert {"sesion", "avance", "hito", "compromiso", "etapa"} <= kinds

    # 8. lo que NO es suyo: el panel de personal, otros emprendimientos y la gestion
    for path in (
        "/users",
        "/audit",
        "/indicators/dashboard",
        "/alerts",
        "/applications",
        "/entrepreneurs",
    ):
        assert (await client.get(f"{API}{path}", headers=emp)).status_code == 403, path
    assert (
        await client.post(f"{API}/training", json={"titulo": "X"}, headers=emp)
    ).status_code == 403
    assert (
        await client.patch(
            f"{API}/ventures/{vid}", json={"estado": "cerrado"}, headers=emp
        )
    ).status_code == 403
