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
- Móvil: `XpBadgesSection` en la pestaña Perfil (barra de nivel, insignias y movimientos).
- Web: catálogo de insignias en `/catalogs` (`GET/PATCH /badges`).

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/gamification/router.py` (`/gamification/me`, `/badges`), `Backend/EmprendeU/src/emprendeu/modules/gamification/levels.py` |
| Móvil | `Frontend/app_emprendeu/lib/features/gamification/presentation/widgets/xp_badges_section.dart` |
| Web (catálogo) | `Frontend/emprendeu/features/gamification/components/badges-grid.tsx` |

## Por qué se hizo así

- El total se calcula desde los movimientos (fuente de verdad) en vez de guardar un acumulado que podría desincronizarse.

## Verificación

- `Backend/EmprendeU/tests/test_entrepreneurs_api.py::test_cu06_progreso_visible_para_el_personal_y_cu07_cu08_del_emprendedor`
- `Backend/EmprendeU/tests/test_gamification_api.py::test_completar_retos_otorga_xp_una_vez_nivel_e_insignias`

## Pendiente

- Ninguno conocido.
