# CU21 — Generar Reportes

| Campo | Valor |
|---|---|
| Prioridad | Media |
| Actor(es) | Coordinador |
| Cliente | Web |
| Fase del plan | F3 |
| **Estado** | **✅ Completado** |

## Descripción

Reportes con filtros, vista previa y exportación a CSV.

## Qué se hizo

- `GET /indicators/reports/{kind}` (vista previa) y `GET /indicators/reports/{kind}/export` (CSV).
- Web `/reports` (`ReportsScreen`): filtros de periodo y etapa en la URL, vista previa de 50 filas y descarga por el *route handler* `app/(app)/reports/export/route.ts`.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/indicators/router.py`, `Backend/EmprendeU/src/emprendeu/modules/indicators/service.py`, `Backend/EmprendeU/src/emprendeu/core/csv_export.py` |
| Web | `Frontend/emprendeu/features/indicators/components/reports-screen.tsx`, `Frontend/emprendeu/app/(app)/reports/page.tsx`, `Frontend/emprendeu/app/(app)/reports/export/route.ts` |

## Por qué se hizo así

- Se reutilizó la exportación CSV de la auditoría (`core/csv_export.py`) como pide el plan.

## Verificación

- `Backend/EmprendeU/tests/test_dashboard_reports_api.py::test_reportes_vista_previa_filtros_y_csv`

## Pendiente

- Solo CSV; no hay exportación a PDF o Excel.
