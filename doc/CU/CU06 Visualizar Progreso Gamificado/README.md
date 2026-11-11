# CU06 — Visualizar Progreso Gamificado

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Emprendedor (app), asesor y coordinador (web) |
| Cliente | Web y app móvil |
| Fase del plan | F4 |
| **Estado** | **✅ Completado** |

## Descripción

Ver el «Camino» del emprendimiento: XP, nivel, etapas completadas/actual/pendientes y los retos.

## Qué se hizo

- `GET /journey` devuelve el camino (retos ordenados y su estado de desbloqueo); el personal puede pedir el de un emprendimiento ajeno, un emprendedor ajeno no.
- Móvil: pestaña «Camino» (`JourneyScreen` con `JourneyPath`) e Inicio con `ProgressCard` y `NextChallengeCard`.
- Web: `/ventures/[id]/progress` (`JourneyScreen` de solo lectura) enlazado desde la lista de emprendimientos.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/gamification/` (`router.py` → `/journey`, `service.py`, `levels.py`) |
| Web | `Frontend/emprendeu/features/gamification/components/journey-screen.tsx`, `Frontend/emprendeu/app/(app)/ventures/[id]/progress/page.tsx` |
| Móvil | `Frontend/app_emprendeu/lib/features/gamification/presentation/screens/journey_screen.dart`, `widgets/journey_path.dart`; `Frontend/app_emprendeu/lib/features/home/presentation/widgets/progress_card.dart` |

## Por qué se hizo así

- Un único endpoint sirve a los dos clientes; el permiso decide si se ve el camino propio o el de otro.
- En la web es solo lectura: el personal observa, el emprendedor es quien cumple retos.

## Verificación

- `Backend/EmprendeU/tests/test_gamification_api.py::test_camino_inicial_y_orden_de_desbloqueo`, `test_personal_ve_camino_ajeno_y_emprendedor_ajeno_no`
- `Backend/EmprendeU/tests/test_entrepreneurs_api.py::test_cu06_progreso_visible_para_el_personal_y_cu07_cu08_del_emprendedor`
- `Frontend/app_emprendeu/test/features/gamification/journey_screen_test.dart`, `Frontend/app_emprendeu/test/features/home/home_screen_test.dart`

## Pendiente

- Ninguno conocido.
