# CU08 — Consultar Puntos de Experiencia e Insignias

| Campo | Valor |
|---|---|
| Prioridad | Media |
| Actor(es) | Emprendedor |
| Cliente | App móvil |
| Fase del plan | F4 |
| **Estado** | **✅ Completado** |

## Descripción

El emprendedor consulta su XP total, nivel, insignias obtenidas y últimos movimientos.

## Qué se hizo

- `GET /gamification/me`: XP calculado desde `movimientos_xp`, nivel y avance al siguiente, insignias y movimientos.
- Niveles fijos 0 / 200 / 400 / 700 / 1100 XP.
- Móvil: `XpBadgesSection` en la pestaña Perfil es el resumen (nivel, barra, «N de M insignias») y enlaza a la pantalla **«Experiencia e insignias»** (`/xp`, `XpBadgesScreen`) con nivel, insignias, historial de movimientos y *pull to refresh*.
- Tocar una insignia abre una hoja con su criterio, la recompensa en XP y la fecha de obtención (o «Aún no la obtienes»).
- Excepciones del CU: sin puntos ni insignias → mensaje «Aún no tienes puntos ni insignias» con acceso al Camino; error al recuperar → mensaje del `Failure` y «Reintentar»; sesión inválida → la maneja `AuthInterceptor` (401 cierra la sesión).
- Web: catálogo de insignias en `/catalogs` (`GET/PATCH /badges`).

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/gamification/router.py` (`/gamification/me`, `/badges`), `Backend/EmprendeU/src/emprendeu/modules/gamification/levels.py` |
| Móvil | `Frontend/app_emprendeu/lib/features/gamification/presentation/screens/xp_badges_screen.dart`, `widgets/xp_badges_section.dart`, `widgets/badge_tile.dart`, `widgets/xp_level_card.dart`, `widgets/xp_movement_row.dart`, `widgets/xp_empty_state.dart` |
| Web (catálogo) | `Frontend/emprendeu/features/gamification/components/badges-grid.tsx` |

## Por qué se hizo así

- El total se calcula desde los movimientos (fuente de verdad) en vez de guardar un acumulado que podría desincronizarse.

## Verificación

- `Backend/EmprendeU/tests/test_entrepreneurs_api.py::test_cu06_progreso_visible_para_el_personal_y_cu07_cu08_del_emprendedor`
- `Backend/EmprendeU/tests/test_gamification_api.py::test_completar_retos_otorga_xp_una_vez_nivel_e_insignias`
- `Frontend/app_emprendeu/test/features/gamification/xp_badges_screen_test.dart` (estado vacío, datos, detalle de insignia, error y reintento) y `test/features/ventures/ventures_screens_test.dart` (resumen en Perfil)

## Pendiente

- Ninguno conocido.
