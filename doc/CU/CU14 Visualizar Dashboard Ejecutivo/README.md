# CU14 — Visualizar Dashboard Ejecutivo

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Coordinador |
| Cliente | Web |
| Fase del plan | F3 |
| **Estado** | **✅ Completado** |

## Descripción

Panel de indicadores del programa con filtros de periodo y etapa (solo lectura).

## Qué se hizo

- `GET /indicators/dashboard` con filtros de periodo y etapa (`InvalidPeriod` si el rango no es válido).
- `GET /indicators/overview` alimenta el Resumen (`/`) junto con la actividad reciente de la auditoría.
- Web `/dashboard` (`DashboardScreen`, `PeriodFilters`), filtros en la URL.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/indicators/` (`router.py`, `service.py`), `Backend/EmprendeU/src/emprendeu/core/periods.py` |
| Web | `Frontend/emprendeu/features/indicators/components/dashboard-screen.tsx`, `period-filters.tsx`, `overview-view.tsx`, `Frontend/emprendeu/app/(app)/dashboard/page.tsx` |

## Por qué se hizo así

- Cálculo en el backend para que web y reportes (CU21) usen las mismas cifras.

## Verificación

- `Backend/EmprendeU/tests/test_dashboard_reports_api.py::test_dashboard_ejecutivo_con_filtros_de_periodo_y_etapa`
- `Backend/EmprendeU/tests/test_alerts_indicators_api.py::test_indicadores_y_resumen_del_panel`

## Pendiente

- Ninguno conocido.
