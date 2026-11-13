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

- `POST /journey/challenges/{reto_id}/complete` registra el cumplimiento y crea el movimiento en `movimientos_xp`. Acepta un cuerpo opcional `{evidencia_texto, documento_id}`.
- Cada reto tiene `criterio_completado` (requisitos que ve el emprendedor) y `requiere_evidencia`. Si la exige y no llega un texto de al menos 10 caracteres ni un documento del emprendimiento, responde 422 `criteria_not_met` y no registra nada. Un `documento_id` ajeno o inexistente también es 422.
- La evidencia queda en `emprendimiento_retos` (`evidencia_texto`, `documentosid`); migración `31342fe243b8`.
- Rechaza un reto bloqueado (`ChallengeLocked`) o ya cumplido (`ChallengeAlreadyCompleted`): el XP se da **una sola vez**.
- Al cumplir se recalcula nivel e insignias.
- Móvil: hoja `ChallengeSheet` desde el Camino; muestra los requisitos y, si el reto exige evidencia, un campo de texto y un archivo opcional (subido con la feature `documents`); cumplir un reto **exige conexión**.
- Web: el personal edita el catálogo de retos, su XP y si exigen evidencia en `/catalogs` (`POST/PATCH /challenges`).

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/gamification/service.py`, `Backend/EmprendeU/src/emprendeu/modules/gamification/exceptions.py` |
| Móvil | `Frontend/app_emprendeu/lib/features/gamification/presentation/widgets/challenge_sheet.dart`, `domain/usecases/` |
| Web (catálogo) | `Frontend/emprendeu/features/gamification/components/challenges-table.tsx`, `Frontend/emprendeu/app/(app)/catalogs/page.tsx` |

## Por qué se hizo así

- El orden y el XP los valida el servidor; por eso no se permite cumplir sin conexión (evita XP duplicado o retos fuera de orden).

## Verificación

- `Backend/EmprendeU/tests/test_gamification_api.py::test_completar_retos_otorga_xp_una_vez_nivel_e_insignias`, `test_catalogo_admin_cambia_xp_y_crea_retos`, `test_reto_con_evidencia_obligatoria_verifica_criterios`, `test_reto_con_evidencia_acepta_documento_del_emprendimiento`
- `Frontend/app_emprendeu/test/features/gamification/journey_screen_test.dart`

## Pendiente

- Ninguno conocido.
