# CU07 — Registrar Cumplimiento de Reto

| Campo | Valor |
|---|---|
| Prioridad | Media |
| Actor(es) | Emprendedor |
| Cliente | App móvil |
| Fase del plan | F4 |
| **Estado** | **✅ Completado** |

## Descripción

El emprendedor marca como cumplido el reto desbloqueado y gana su XP.

## Qué se hizo

- `POST /journey/challenges/{reto_id}/complete` registra el cumplimiento y crea el movimiento en `movimientos_xp`.
- Rechaza un reto bloqueado (`ChallengeLocked`) o ya cumplido (`ChallengeAlreadyCompleted`): el XP se da **una sola vez**.
- Al cumplir se recalcula nivel e insignias.
- Móvil: hoja `ChallengeSheet` desde el Camino; cumplir un reto **exige conexión**.
- Web: el personal edita el catálogo de retos y su XP en `/catalogs` (`POST/PATCH /challenges`).

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/gamification/service.py`, `Backend/EmprendeU/src/emprendeu/modules/gamification/exceptions.py` |
| Móvil | `Frontend/app_emprendeu/lib/features/gamification/presentation/widgets/challenge_sheet.dart`, `domain/usecases/` |
| Web (catálogo) | `Frontend/emprendeu/features/gamification/components/challenges-table.tsx`, `Frontend/emprendeu/app/(app)/catalogs/page.tsx` |

## Por qué se hizo así

- El orden y el XP los valida el servidor; por eso no se permite cumplir sin conexión (evita XP duplicado o retos fuera de orden).

## Verificación

- `Backend/EmprendeU/tests/test_gamification_api.py::test_completar_retos_otorga_xp_una_vez_nivel_e_insignias`, `test_catalogo_admin_cambia_xp_y_crea_retos`
- `Frontend/app_emprendeu/test/features/gamification/journey_screen_test.dart`

## Pendiente

- Ninguno conocido.
