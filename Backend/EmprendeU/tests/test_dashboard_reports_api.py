"""Dashboard ejecutivo (CU14) y reportes con vista previa y CSV (CU21)."""

from datetime import UTC, date, datetime, timedelta

from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import MakeUser

API = "/api/v1"


async def _world(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
):
    """Dos emprendimientos: Alfa (Incubación, con actividad) y Beta (Preincubación, inactivo)."""
    await make_user(rol="administrador", email="admin@test.com")
    await make_user(rol="coordinador", email="coord@test.com")
    await make_user(
        rol="asesor", email="m@test.com", nombre="Marcelo", apellido="Cuellar"
    )
    await make_user(email="e1@test.com", nombre="Ana", apellido="Alfa")
    await make_user(email="e2@test.com", nombre="Beto", apellido="Beta")
    h = {k: await login(f"{k}@test.com") for k in ("admin", "coord", "m", "e1", "e2")}

    async def venture(name: str, who: str) -> int:
        r = await client.post(f"{API}/ventures", json={"nombre": name}, headers=h[who])
        return r.json()["emprendimiento_id"]

    alfa, beta = await venture("Alfa", "e1"), await venture("Beta", "e2")
    stages = {
        s["nombre"]: s
        for s in (await client.get(f"{API}/stages", headers=h["e1"])).json()
    }
    await client.put(
        f"{API}/ventures/{alfa}/stage",
        json={"etapa_id": stages["Incubación"]["etapa_id"]},
        headers=h["coord"],
    )
    me = (await client.get(f"{API}/auth/me", headers=h["e1"])).json()["usuario_id"]

    # actividad de Alfa: una sesión realizada hace 2 días, un avance, 2 compromisos (1 vencido), 1 indicador
    when = (datetime.now(UTC) - timedelta(days=2)).isoformat()
    await client.post(
        f"{API}/mentoring/sessions/register",
        json={"emprendimiento_id": alfa, "fecha_realizada": when, "tema": "Costos"},
        headers=h["coord"],
    )
    await client.post(
        f"{API}/mentoring/progress",
        json={"observaciones": "Primer cliente"},
        headers=h["e1"],
    )
    for description, due in (
        ("Subir fotos", (datetime.now(UTC) + timedelta(days=5)).isoformat()),
        ("Entregar costos", (datetime.now(UTC) - timedelta(days=3)).isoformat()),
    ):
        await client.post(
            f"{API}/mentoring/commitments",
            json={
                "emprendimiento_id": alfa,
                "descripcion": description,
                "usuario_id": me,
                "fecha_limite": due,
            },
            headers=h["coord"],
        )
    types = (await client.get(f"{API}/indicators/types", headers=h["e1"])).json()
    ventas = next(t for t in types if t["nombre"] == "Ventas mensuales")
    await client.post(
        f"{API}/indicators/ventures/{alfa}/values",
        json={
            "tipo_indicador_id": ventas["tipo_indicador_id"],
            "valor": "1500.50",
            "periodo": "2026-10",
        },
        headers=h["e1"],
    )
    # Beta lleva 40 días sin actividad: la deteccion genera una alerta
    await session.execute(
        text(
            "UPDATE cieu.emprendimiento SET fecha_creacion = now() - interval '40 days' WHERE nombre = 'Beta'"
        )
    )
    await client.post(f"{API}/alerts/evaluate", headers=h["admin"])
    return h, alfa, beta, stages


async def test_dashboard_ejecutivo_con_filtros_de_periodo_y_etapa(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, alfa, beta, stages = await _world(client, make_user, login, session)
    url = f"{API}/indicators/dashboard"

    # solo personal con reportes:consulta; el asesor y el emprendedor no
    for who in ("m", "e1"):
        assert (await client.get(url, headers=h[who])).status_code == 403
    assert (await client.get(url, headers=h["admin"])).status_code == 200

    d = (await client.get(url, headers=h["coord"])).json()
    assert d["emprendimientos_total"] == 2
    assert {x["etapa"]: x["total"] for x in d["por_etapa"]} == {
        "Preincubación": 1,
        "Incubación": 1,
        "Crecimiento": 0,
        "Graduación": 0,
    }
    assert d["sesiones"] == {"programadas": 0, "realizadas": 1, "canceladas": 0}
    assert d["compromisos"] == {"pendientes": 2, "vencidos": 1, "cumplidos_periodo": 0}
    assert d["avances"] == 1
    assert d["alertas"]["abiertas"] == 1 and d["alertas"]["por_tipo"] == {
        "inactividad": 1
    }
    assert [
        (i["nombre"], i["registros"], float(i["promedio"])) for i in d["indicadores"]
    ] == [("Ventas mensuales", 1, 1500.5)]

    # filtro por etapa: solo los emprendimientos de esa etapa actual
    inc = (
        await client.get(
            f"{url}?etapa_id={stages['Incubación']['etapa_id']}", headers=h["coord"]
        )
    ).json()
    assert inc["emprendimientos_total"] == 1 and inc["alertas"]["abiertas"] == 0
    assert inc["sesiones"]["realizadas"] == 1 and inc["compromisos"]["vencidos"] == 1
    pre = (
        await client.get(
            f"{url}?etapa_id={stages['Preincubación']['etapa_id']}", headers=h["coord"]
        )
    ).json()
    assert pre["emprendimientos_total"] == 1 and pre["sesiones"]["realizadas"] == 0
    assert pre["alertas"]["abiertas"] == 1 and pre["indicadores"] == []

    # filtro por periodo: la sesión fue hace 2 días; el periodo de 2000 no la incluye
    today = date.today()
    recent = (
        await client.get(
            f"{url}?desde={today - timedelta(days=5)}&hasta={today}", headers=h["coord"]
        )
    ).json()
    assert recent["sesiones"]["realizadas"] == 1 and recent["avances"] == 1
    old = (
        await client.get(f"{url}?desde=2000-01-01&hasta=2000-01-31", headers=h["coord"])
    ).json()
    assert old["sesiones"]["realizadas"] == 0 and old["avances"] == 0
    assert old["alertas"]["abiertas"] == 0 and old["indicadores"] == []
    # lo que es «hoy» (pendientes y vencidos) no depende del periodo
    assert old["compromisos"]["pendientes"] == 2

    bad = await client.get(
        f"{url}?desde=2026-02-01&hasta=2026-01-01", headers=h["coord"]
    )
    assert bad.status_code == 422 and bad.json()["error"]["code"] == "invalid_period"


async def test_reportes_vista_previa_filtros_y_csv(
    client: AsyncClient, make_user: MakeUser, login, session: AsyncSession
) -> None:
    h, alfa, beta, stages = await _world(client, make_user, login, session)
    base = f"{API}/indicators/reports"

    assert (await client.get(f"{base}/resumen", headers=h["e1"])).status_code == 403
    assert (
        await client.get(f"{base}/inexistente", headers=h["coord"])
    ).status_code == 422

    # --- resumen por emprendimiento
    r = (await client.get(f"{base}/resumen", headers=h["coord"])).json()
    assert (
        r["titulo"] == "Resumen por emprendimiento"
        and r["total"] == 2
        and not r["truncado"]
    )
    by_name = {row["emprendimiento"]: row for row in r["filas"]}
    assert by_name["Alfa"]["etapa"] == "Incubación"
    assert by_name["Alfa"]["sesiones_realizadas"] == 1
    assert (
        by_name["Alfa"]["compromisos_pendientes"] == 2
        and by_name["Alfa"]["compromisos_vencidos"] == 1
    )
    assert by_name["Alfa"]["ultimo_avance"] != ""
    assert (
        by_name["Beta"]["alertas_sin_resolver"] == 1
        and by_name["Beta"]["sesiones_realizadas"] == 0
    )
    assert [c["clave"] for c in r["columnas"]][:3] == [
        "emprendimiento",
        "sector",
        "etapa",
    ]

    # vista previa recortada pero con el total
    short = (await client.get(f"{base}/resumen?limit=1", headers=h["coord"])).json()
    assert (
        len(short["filas"]) == 1 and short["total"] == 2 and short["truncado"] is True
    )
    # filtro por etapa
    only = (
        await client.get(
            f"{base}/resumen?etapa_id={stages['Incubación']['etapa_id']}",
            headers=h["coord"],
        )
    ).json()
    assert [row["emprendimiento"] for row in only["filas"]] == ["Alfa"]

    # --- sesiones, alertas e indicadores
    sessions = (await client.get(f"{base}/sesiones", headers=h["coord"])).json()
    assert [
        (x["emprendimiento"], x["tema"], x["estado"]) for x in sessions["filas"]
    ] == [("Alfa", "Costos", "realizada")]
    window = "desde=2000-01-01&hasta=2000-01-31"
    assert (await client.get(f"{base}/sesiones?{window}", headers=h["coord"])).json()[
        "total"
    ] == 0
    alerts = (await client.get(f"{base}/alertas", headers=h["coord"])).json()
    assert [(x["emprendimiento"], x["tipo"], x["estado"]) for x in alerts["filas"]] == [
        ("Beta", "inactividad", "abierta")
    ]
    values = (await client.get(f"{base}/indicadores", headers=h["coord"])).json()
    assert [
        (x["emprendimiento"], x["indicador"], x["valor"], x["unidad"])
        for x in values["filas"]
    ] == [("Alfa", "Ventas mensuales", 1500.5, "Bs")]
    assert (
        await client.get(
            f"{base}/resumen?desde=2026-02-01&hasta=2026-01-01", headers=h["coord"]
        )
    ).status_code == 422

    # --- exportación CSV (mismo patrón que la auditoría): todas las filas, con BOM y tildes
    csv = await client.get(f"{base}/resumen/export", headers=h["coord"])
    assert csv.status_code == 200 and csv.headers["content-type"].startswith("text/csv")
    assert "reporte-resumen.csv" in csv.headers["content-disposition"]
    lines = csv.text.lstrip("﻿").strip().splitlines()
    assert lines[0].startswith("Emprendimiento,Sector,Etapa,Sesiones realizadas")
    assert "Último avance" in lines[0]
    assert len(lines) == 3 and lines[1].startswith("Alfa,")
    assert (
        await client.get(f"{base}/resumen/export", headers=h["m"])
    ).status_code == 403

    # la exportación queda en la bitácora
    audit = (
        await client.get(f"{API}/audit?categoria=negocio", headers=h["admin"])
    ).json()
    assert any(e["accion"] == "negocio.reporte" for e in audit["items"])
