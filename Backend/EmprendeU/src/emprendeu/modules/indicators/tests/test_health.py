"""Regla del puntaje de salud (función pura, sin base de datos)."""

from emprendeu.modules.indicators.health import HealthSignals, score_venture


def test_sin_senales_de_riesgo_es_verde_y_sin_motivos() -> None:
    r = score_venture(HealthSignals(idle_days=3, stage_days=20, sentiment_recent=0.4))
    assert (r.score, r.level, r.reasons) == (100, "verde", [])


def test_cada_senal_resta_y_deja_su_motivo() -> None:
    r = score_venture(
        HealthSignals(
            open_alerts=1,
            overdue_commitments=2,
            idle_days=45,
            idle_limit_days=30,
            stage_days=130,
        )
    )
    # 100 - 10 (alerta) - 16 (2 compromisos) - 10 (inactivo) - 10 (etapa lenta)
    assert r.score == 54 and r.level == "ambar"
    assert r.reasons == [
        "1 alerta sin resolver",
        "2 compromisos vencidos",
        "45 días sin actividad",
        "130 días en la misma etapa",
    ]


def test_los_topes_evitan_que_una_senal_lo_domine_y_no_baja_de_cero() -> None:
    capped = score_venture(HealthSignals(open_alerts=9))
    assert capped.score == 70  # tope de 30 por alertas
    worst = score_venture(
        HealthSignals(
            open_alerts=9,
            overdue_commitments=9,
            idle_days=200,
            stage_days=400,
            sentiment_recent=-0.8,
        )
    )
    assert worst.score == 0 and worst.level == "rojo"


def test_sentimiento_bajo_o_en_caida() -> None:
    low = score_venture(HealthSignals(sentiment_recent=-0.3))
    assert low.score == 85 and low.reasons == ["ánimo bajo en el coach"]
    drop = score_venture(HealthSignals(sentiment_recent=0.2, sentiment_previous=0.6))
    assert drop.score == 90 and drop.reasons == ["el ánimo en el coach bajó"]
    stable = score_venture(HealthSignals(sentiment_recent=0.5, sentiment_previous=0.6))
    assert stable.reasons == []


def test_inactividad_doble_resta_mas() -> None:
    assert score_venture(HealthSignals(idle_days=61, idle_limit_days=30)).score == 80
