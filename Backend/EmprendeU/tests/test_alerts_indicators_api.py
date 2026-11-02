"""Alertas de riesgo, parametros e indicadores / resumen del panel."""

from datetime import UTC, datetime, timedelta

from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from emprendeu.modules.ai_assistant.models import AnalisisSentimiento
from emprendeu.modules.mentoring.models import Compromiso, SesionAcompanamiento
from tests.conftest import MakeUser

API = "/api/v1"


async def _world(client: AsyncClient, make_user: MakeUser, login):
    admin = await make_user(rol="administrador", email="admin@test.com")
    await make_user(rol="coordinador", email="coord@test.com")
    mentor = await make_user(rol="asesor", email="m@test.com")
    emp = await make_user(email="e@test.com")
    h = {k: await login(f"{k}@test.com") for k in ("admin", "coord", "m", "e")}
    vid = (
        await client.post(f"{API}/ventures", json={"nombre": "Sabores"}, headers=h["e"])
    ).json()["emprendimiento_id"]
    return h, vid, admin, mentor, emp


async def test_parametros_se_validan_y_se_auditan(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, *_ = await _world(client, make_user, login)
    current = (await client.get(f"{API}/alerts/settings", headers=h["admin"])).json()
    assert current["inactividad_dias"] == 14 and current["caida_sentimiento_pct"] == 25
    assert (
        current["periodos_consecutivos"] == 2
        and current["alertar_incumplimiento"] is False
    )

    assert (
        await client.get(f"{API}/alerts/settings", headers=h["e"])
    ).status_code == 403
    new = {
        **{k: v for k, v in current.items() if k != "fecha_actualizacion"},
        "inactividad_dias": 7,
    }
    saved = await client.put(f"{API}/alerts/settings", json=new, headers=h["admin"])
    assert saved.status_code == 200 and saved.json()["inactividad_dias"] == 7
    assert (
        await client.put(
            f"{API}/alerts/settings",
            json={**new, "inactividad_dias": 0},
            headers=h["admin"],
        )
    ).status_code == 422
    audit = (
        await client.get(f"{API}/audit?categoria=config", headers=h["admin"])
    ).json()
    item = next(e for e in audit["items"] if e["accion"] == "config.parametros")
    assert "Inactividad 7" in item["objeto"]

    # CU25: plazo por defecto de los compromisos (1-90 dias), validado y auditado
    assert current["dias_limite_compromiso"] == 7
    url = f"{API}/alerts/settings"
    for bad in (0, 91):
        rejected = await client.put(
            url, json={**new, "dias_limite_compromiso": bad}, headers=h["admin"]
        )
        assert rejected.status_code == 422
    changed = await client.put(
        url, json={**new, "dias_limite_compromiso": 10}, headers=h["coord"]
    )
    assert changed.status_code == 200 and changed.json()["dias_limite_compromiso"] == 10
    # un cliente anterior que no lo envia no lo pisa
    legacy = {k: v for k, v in new.items() if k != "dias_limite_compromiso"}
    kept = await client.put(url, json=legacy, headers=h["admin"])
    assert kept.json()["dias_limite_compromiso"] == 10
    audit = (
        await client.get(f"{API}/audit?categoria=config", headers=h["admin"])
    ).json()
    last = [e for e in audit["items"] if e["accion"] == "config.parametros"]
    assert any("plazo de compromisos 10 dias" in e["objeto"] for e in last)
    assert len(last) >= 3  # cada guardado correcto queda en la bitacora


async def test_deteccion_de_inactividad_sin_duplicados(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, vid, *_ = await _world(client, make_user, login)
    first = await client.post(f"{API}/alerts/evaluate", headers=h["admin"])
    assert first.json() == {
        "creadas": 0,
        "por_tipo": {},
    }  # recien creado: no esta inactivo

    await session.execute(
        text(
            "UPDATE cieu.emprendimiento SET fecha_creacion = now() - interval '40 days'"
        )
    )
    run = (await client.post(f"{API}/alerts/evaluate", headers=h["admin"])).json()
    assert run == {"creadas": 1, "por_tipo": {"inactividad": 1}}
    again = (await client.post(f"{API}/alerts/evaluate", headers=h["admin"])).json()
    assert again["creadas"] == 0  # ya hay una abierta

    assert (
        await client.post(f"{API}/alerts/evaluate", headers=h["coord"])
    ).status_code == 403
    listing = (await client.get(f"{API}/alerts", headers=h["coord"])).json()
    alert = listing["items"][0]
    assert listing["total"] == 1 and alert["emprendimiento"] == "Sabores"
    assert (
        alert["tipo"] == "inactividad"
        and alert["prioridad"] == "alta"
        and alert["estado"] == "abierta"
    )

    # una alerta no modifica el emprendimiento
    assert (await client.get(f"{API}/ventures/{vid}", headers=h["coord"])).json()[
        "estado"
    ] == "activo"
    done = await client.patch(
        f"{API}/alerts/{alert['alerta_id']}",
        json={"estado": "atendida"},
        headers=h["coord"],
    )
    assert done.json()["estado"] == "atendida"
    assert (
        await client.get(f"{API}/alerts?estado=abierta", headers=h["coord"])
    ).json()["total"] == 0
    # cerrada la anterior, una nueva evaluacion puede volver a alertar
    assert (await client.post(f"{API}/alerts/evaluate", headers=h["admin"])).json()[
        "creadas"
    ] == 1


async def test_sentimiento_y_compromisos_vencidos(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, vid, _, mentor, emp = await _world(client, make_user, login)
    eid = (await client.get(f"{API}/entrepreneurs/me", headers=h["e"])).json()[
        "emprendedor_id"
    ]
    now = datetime.now(UTC)
    for weeks_ago, idx in ((2, 0.8), (1, 0.2), (0, -0.4)):
        session.add(
            AnalisisSentimiento(
                emprendedor_id=eid, indice=idx, fecha=now - timedelta(weeks=weeks_ago)
            )
        )
    sesion = SesionAcompanamiento(
        emprendimiento_id=vid, tipo_id=1, estado="realizada", fecha_programada=now
    )
    session.add(sesion)
    await session.flush()
    session.add(
        Compromiso(
            sesion_acompanamiento_id=sesion.sesion_acompanamiento_id,
            emprendimiento_id=vid,
            registrado_por_usuario_id=mentor.usuario_id,
            responsable_usuario_id=emp.usuario_id,
            descripcion="Subir fotos",
            estado="pendiente",
            fecha_limite=now - timedelta(days=3),
        )
    )
    await session.flush()

    # con el parametro apagado no se alerta por compromisos
    first = (await client.post(f"{API}/alerts/evaluate", headers=h["admin"])).json()
    assert first["por_tipo"] == {"sentimiento": 1}

    settings = (await client.get(f"{API}/alerts/settings", headers=h["admin"])).json()
    settings.pop("fecha_actualizacion")
    settings["alertar_incumplimiento"] = True
    await client.put(f"{API}/alerts/settings", json=settings, headers=h["admin"])
    second = (await client.post(f"{API}/alerts/evaluate", headers=h["admin"])).json()
    assert second["por_tipo"] == {"compromiso_vencido": 1}
    texto = (
        await client.get(f"{API}/alerts?tipo=sentimiento", headers=h["admin"])
    ).json()["items"][0]["descripcion"]
    assert "no un diagnostico" in texto


async def test_alertas_segun_rol_y_notificaciones(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, vid, _, mentor, _ = await _world(client, make_user, login)
    await session.execute(
        text(
            "UPDATE cieu.emprendimiento SET fecha_creacion = now() - interval '40 days'"
        )
    )
    await client.post(f"{API}/alerts/evaluate", headers=h["admin"])

    # el asesor solo ve alertas de emprendimientos que tiene asignados
    assert (await client.get(f"{API}/alerts", headers=h["m"])).json()["total"] == 0
    await client.put(
        f"{API}/mentoring/mentors/{mentor.usuario_id}/enabled",
        json={"habilitado": True},
        headers=h["coord"],
    )
    await client.post(
        f"{API}/mentoring/assignments",
        json={"usuario_id": mentor.usuario_id, "emprendimiento_id": vid},
        headers=h["coord"],
    )
    assert (await client.get(f"{API}/alerts", headers=h["m"])).json()["total"] == 1

    settings = (await client.get(f"{API}/alerts/settings", headers=h["admin"])).json()
    settings.pop("fecha_actualizacion")
    await client.put(
        f"{API}/alerts/settings",
        json={**settings, "notificar_asesor": False, "notificar_coordinador": False},
        headers=h["admin"],
    )
    assert (await client.get(f"{API}/alerts", headers=h["m"])).json()["total"] == 0
    assert (await client.get(f"{API}/alerts", headers=h["coord"])).json()["total"] == 0
    assert (await client.get(f"{API}/alerts", headers=h["admin"])).json()["total"] == 1


async def test_indicadores_y_resumen_del_panel(
    client: AsyncClient, make_user: MakeUser, login
) -> None:
    h, vid, *_ = await _world(client, make_user, login)
    types = (await client.get(f"{API}/indicators/types", headers=h["e"])).json()
    assert {t["nombre"] for t in types} >= {"Ventas mensuales", "Clientes activos"}
    ventas = next(t for t in types if t["nombre"] == "Ventas mensuales")

    added = await client.post(
        f"{API}/indicators/ventures/{vid}/values",
        json={
            "tipo_indicador_id": ventas["tipo_indicador_id"],
            "valor": "1500.50",
            "periodo": "2026-10",
        },
        headers=h["e"],
    )
    assert added.status_code == 201 and added.json()["unidad"] == "Bs"
    values = (
        await client.get(f"{API}/indicators/ventures/{vid}/values", headers=h["coord"])
    ).json()
    assert len(values) == 1 and float(values[0]["valor"]) == 1500.5
    await make_user(email="otro@test.com")
    other = await login("otro@test.com")
    assert (
        await client.get(f"{API}/indicators/ventures/{vid}/values", headers=other)
    ).status_code == 403
    bad = await client.post(
        f"{API}/indicators/ventures/{vid}/values",
        json={"tipo_indicador_id": 99999, "valor": "1", "periodo": "x"},
        headers=h["e"],
    )
    assert bad.status_code == 404
    new_type = await client.post(
        f"{API}/indicators/types",
        json={"nombre": "NPS", "unidad": "pts"},
        headers=h["coord"],
    )
    assert new_type.status_code == 201

    assert (
        await client.get(f"{API}/indicators/overview", headers=h["e"])
    ).status_code == 403
    overview = (
        await client.get(f"{API}/indicators/overview", headers=h["admin"])
    ).json()
    assert overview["usuarios"] == {
        "total": 5,
        "habilitadas": 5,
        "deshabilitadas": 0,
        "por_rol": {
            "administrador": 1,
            "coordinador": 1,
            "asesor": 1,
            "emprendedor": 2,
        },
    }
    assert (
        overview["emprendimientos_activos"] == 1 and overview["alertas_abiertas"] == 0
    )
    assert overview["acciones_auditadas"] >= 4
    names = {s["nombre"]: s["estado"] for s in overview["servicios"]}
    assert (
        names["PostgreSQL"] == "operativo"
        and names["Motor de IA (Ollama + RAG)"] == "operativo"
    )


async def test_gestion_de_alertas_revisada_atendida_y_quien_la_atendio(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    """CU13: coordinacion y asesor (solo de sus emprendimientos) gestionan las alertas."""
    h, vid, _, mentor, _ = await _world(client, make_user, login)
    await session.execute(
        text(
            "UPDATE cieu.emprendimiento SET fecha_creacion = now() - interval '40 days'"
        )
    )
    await client.post(f"{API}/alerts/evaluate", headers=h["admin"])
    alert = (await client.get(f"{API}/alerts", headers=h["coord"])).json()["items"][0]
    url = f"{API}/alerts/{alert['alerta_id']}"

    # el emprendedor (tiene seguimiento:*, pero sobre lo suyo) no ve ni gestiona alertas
    assert (await client.get(f"{API}/alerts", headers=h["e"])).status_code == 403
    assert (
        await client.patch(url, json={"estado": "revisada"}, headers=h["e"])
    ).status_code == 403

    # un asesor sin ese emprendimiento asignado no puede gestionarla
    denied = await client.patch(url, json={"estado": "revisada"}, headers=h["m"])
    assert denied.status_code == 403
    assert denied.json()["error"]["code"] == "alert_not_assigned"

    await client.put(
        f"{API}/mentoring/mentors/{mentor.usuario_id}/enabled",
        json={"habilitado": True},
        headers=h["coord"],
    )
    await client.post(
        f"{API}/mentoring/assignments",
        json={"usuario_id": mentor.usuario_id, "emprendimiento_id": vid},
        headers=h["coord"],
    )

    # revisada: alguien la vio, pero sigue sin resolver (y no se duplica al evaluar)
    reviewed = await client.patch(url, json={"estado": "revisada"}, headers=h["m"])
    assert reviewed.status_code == 200
    assert reviewed.json()["estado"] == "revisada"
    assert reviewed.json()["atendida_por"] is None
    again = (await client.post(f"{API}/alerts/evaluate", headers=h["admin"])).json()
    assert again["creadas"] == 0
    assert (
        await client.get(f"{API}/alerts?estado=revisada", headers=h["coord"])
    ).json()["total"] == 1

    # atendida: queda quien la atendio
    done = await client.patch(url, json={"estado": "atendida"}, headers=h["m"])
    assert done.json()["estado"] == "atendida"
    assert done.json()["atendida_por_id"] == mentor.usuario_id
    assert mentor.nombre in done.json()["atendida_por"]

    # una alerta cerrada no se reabre
    closed = await client.patch(url, json={"estado": "revisada"}, headers=h["coord"])
    assert closed.status_code == 409
    assert closed.json()["error"]["code"] == "alert_closed"

    # cada cambio queda en la bitacora
    audit = (
        await client.get(f"{API}/audit?categoria=negocio", headers=h["admin"])
    ).json()
    managed = [e for e in audit["items"] if e["accion"] == "negocio.alerta"]
    assert len(managed) == 2
