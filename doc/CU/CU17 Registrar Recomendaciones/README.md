# CU17 — Registrar Recomendaciones

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Asesor |
| Cliente | Web (registro); app móvil (consulta en el historial) |
| Fase del plan | F2 |
| **Estado** | **✅ Completado** |

## Descripción

El asesor deja recomendaciones a un emprendimiento, opcionalmente vinculadas a una sesión.

## Qué se hizo

- `POST /mentoring/recommendations` y `POST /sessions/{id}/recommendations`.
- La sesión vinculada debe ser del mismo emprendimiento (`SessionMismatch`).
- `GET /recommendations/me` para el emprendedor; aparecen en el historial (CU19).
- Web: acción «Recomendar» en `/mentoring/sessions`.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/mentoring/router.py`, `Backend/EmprendeU/src/emprendeu/modules/mentoring/service.py` |
| Web | `Frontend/emprendeu/features/mentoring/components/session-forms.tsx` |

## Por qué se hizo así

- La regla de vinculación se aplica en el servicio porque la base no la puede validar por sí sola.

## Verificación

- `Backend/EmprendeU/tests/test_mentoring_api.py::test_recomendaciones_y_compromisos_del_emprendimiento`

## Pendiente

- Ninguno conocido.
