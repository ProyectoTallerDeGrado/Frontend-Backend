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

- `GET /indicators/reports/{kind}` (vista previa) y `GET /indicators/reports/{kind}/export?formato=csv|xlsx` (CSV o Excel; otro formato es 422).
- Web `/reports` (`ReportsScreen`): filtros de periodo y etapa en la URL, vista previa de 50 filas y botones «Exportar Excel» y «Exportar CSV» por el *route handler* `app/(app)/reports/export/route.ts`.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/indicators/router.py`, `Backend/EmprendeU/src/emprendeu/modules/indicators/service.py`, `Backend/EmprendeU/src/emprendeu/core/csv_export.py`, `Backend/EmprendeU/src/emprendeu/core/xlsx_export.py` (`openpyxl`) |
| Web | `Frontend/emprendeu/features/indicators/components/reports-screen.tsx`, `Frontend/emprendeu/app/(app)/reports/page.tsx`, `Frontend/emprendeu/app/(app)/reports/export/route.ts` |

## Por qué se hizo así

- Se reutilizó la exportación CSV de la auditoría (`core/csv_export.py`) como pide el plan; el Excel usa las mismas filas.
- En el Excel los textos se escriben como texto literal: un valor que empieza por `=` no se evalúa como fórmula.

## Verificación

- `Backend/EmprendeU/tests/test_dashboard_reports_api.py::test_reportes_vista_previa_filtros_y_csv` (CSV y Excel)
- `Backend/EmprendeU/tests/test_xlsx_export.py`

## Pendiente

- No hay exportación a PDF (el Excel y el CSV sí).
