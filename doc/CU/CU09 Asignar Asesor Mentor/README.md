# CU09 — Asignar Asesor/Mentor

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Coordinador |
| Cliente | Web |
| Fase del plan | F2 |
| **Estado** | **✅ Completado** |

## Descripción

La coordinación habilita asesores y los asigna a emprendimientos.

## Qué se hizo

- `GET /mentoring/mentors`, `PUT /mentors/{id}/profile` y `PUT /mentors/{id}/enabled` (perfil del mentor).
- `POST /mentoring/assignments`: solo con un asesor `perfil_mentor.habilitado = true` (`MentorNotEnabled`); una asignación activa duplicada se rechaza (`AssignmentExists`).
- `GET /assignments`, `GET /assignments/me` y `PATCH /assignments/{id}/end` (terminar asignación).
- Web `/mentoring/assignments` (`AssignmentsPanel`); el rol asesor no ve este ítem.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/mentoring/` (`router.py`, `service.py`, `exceptions.py`) |
| Web | `Frontend/emprendeu/features/mentoring/components/assignments-panel.tsx`, `screens.tsx`, `Frontend/emprendeu/app/(app)/mentoring/assignments/page.tsx` |

## Por qué se hizo así

- La regla de habilitado y de no duplicar vive en el servicio porque la base no puede validarla por completo (indicación del plan, fase 2).

## Verificación

- `Backend/EmprendeU/tests/test_mentoring_api.py::test_asignaciones`

## Pendiente

- Ninguno conocido.
