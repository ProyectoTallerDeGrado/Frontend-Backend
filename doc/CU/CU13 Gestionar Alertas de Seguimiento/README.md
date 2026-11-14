# CU13 — Gestionar Alertas de Seguimiento

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Coordinador y asesor |
| Cliente | Web |
| Fase del plan | F3 |
| **Estado** | **✅ Completado** |

## Descripción

El sistema genera alertas (inactividad, caída de sentimiento, compromisos vencidos) y el personal las gestiona.

## Qué se hizo

- `GET /alerts` según el rol (el asesor ve las de sus emprendimientos).
- `PATCH /alerts/{id}` cambia el estado a `revisada`, `atendida` o `descartada` y guarda `atendida_por_usuarioid`; una alerta cerrada no se reabre (`AlertClosed`).
- `POST /alerts/evaluate` y job periódico `alerts/jobs.py` (contenedor `alerts-job`) detectan sin duplicar, usando `parametros_seguimiento`.
- Web `/alerts` (`AlertsScreen` y `AlertActions`).

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/alerts/` (`router.py`, `service.py`, `jobs.py`, `repository.py`) |
| Migración | `db/migrations/versions/c9e1a4b7d052_alertas_atendida_por.py` |
| Web | `Frontend/emprendeu/features/alerts/components/alerts-screen.tsx`, `alert-actions.tsx`, `Frontend/emprendeu/app/(app)/alerts/page.tsx` |

## Por qué se hizo así

- `atendida_por_usuarioid` responde «¿quién atendió esta alerta?», que antes no se sabía.
- Detección por cron externo y no por un scheduler dentro de la app: funciona igual con varias réplicas.

## Verificación

- `Backend/EmprendeU/tests/test_alerts_indicators_api.py` (inactividad sin duplicados, sentimiento y compromisos vencidos, alertas por rol, revisada/atendida y quién la atendió)

## Pendiente

- Ninguno conocido.
