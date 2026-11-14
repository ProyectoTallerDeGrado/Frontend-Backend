# CU23 — Consultar Mentorías Programadas

| Campo | Valor |
|---|---|
| Prioridad | Media |
| Actor(es) | Asesor (web) y emprendedor (app) |
| Cliente | Web y app móvil |
| Fase del plan | F2 |
| **Estado** | **✅ Completado** |

## Descripción

Listar las sesiones de mentoría con filtros por estado y periodo.

## Qué se hizo

- `GET /mentoring/sessions/me` (asesor o emprendedor) y `GET /mentoring/sessions` paginado (coordinación), con filtros de estado y periodo.
- Web `/mentoring/sessions`: filtros en la URL.
- Móvil: pestaña «Mentorías» con chips de estado y periodo (`showDateRangePicker`), tarjetas `SessionCard`.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/mentoring/router.py`, `Backend/EmprendeU/src/emprendeu/modules/mentoring/service.py` |
| Web | `Frontend/emprendeu/features/mentoring/components/sessions-view.tsx`, `screens.tsx` |
| Móvil | `Frontend/app_emprendeu/lib/features/mentoring/presentation/screens/mentoring_screen.dart`, `widgets/session_card.dart` |

## Por qué se hizo así

- El plan exige las dos pantallas: el asesor organiza su agenda y el emprendedor ve sus citas.

## Verificación

- `Backend/EmprendeU/tests/test_mentoring_api.py::test_filtros_de_sesiones_por_periodo_y_estado`
- `Frontend/app_emprendeu/test/features/mentoring/mentoring_screens_test.dart`

## Pendiente

- Ninguno conocido.
