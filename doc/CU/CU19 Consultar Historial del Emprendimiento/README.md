# CU19 — Consultar Historial del Emprendimiento

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Personal autorizado (web) y emprendedor (app) |
| Cliente | Web y app móvil |
| Fase del plan | F3 |
| **Estado** | **✅ Completado** |

## Descripción

Línea de tiempo de sesiones, avances, hitos, recomendaciones y compromisos del emprendimiento.

## Qué se hizo

- `GET /mentoring/ventures/{id}/history` (personal) y `GET /mentoring/ventures/me/history` (emprendedor), con `?orden=`.
- Permisos por emprendimiento: nadie ve el historial de otro sin autorización.
- Web `/ventures/[id]/history` (`HistoryScreen`, `?orden=desc`).
- Móvil: botón «Ver historial del emprendimiento» → `/mentoring/history`, alterna «Más reciente primero» / «Cronológico».

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/mentoring/service.py` (construcción de eventos), `Backend/EmprendeU/src/emprendeu/modules/mentoring/router.py` |
| Web | `Frontend/emprendeu/features/mentoring/components/history-screen.tsx`, `Frontend/emprendeu/app/(app)/ventures/[id]/history/page.tsx` |
| Móvil | `Frontend/app_emprendeu/lib/features/mentoring/presentation/screens/history_screen.dart`, `data/models/history_dto.dart`, `domain/entities/history_event.dart` |

## Por qué se hizo así

- Un endpoint que une las fuentes evita que cada cliente reconstruya la línea de tiempo por su cuenta.

## Verificación

- `Backend/EmprendeU/tests/test_mentoring_api.py::test_historial_del_emprendimiento_y_sus_permisos`
- `Frontend/app_emprendeu/test/features/mentoring/mentoring_screens_test.dart`

## Pendiente

- Ninguno conocido.
