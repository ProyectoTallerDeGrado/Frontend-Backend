# CU15 — Gestionar Disponibilidad de Mentor

| Campo | Valor |
|---|---|
| Prioridad | Media |
| Actor(es) | Asesor |
| Cliente | Web |
| Fase del plan | F2 |
| **Estado** | **✅ Completado** |

## Descripción

El asesor define sus horarios disponibles; de ellos salen los turnos que agenda el emprendedor.

## Qué se hizo

- `GET/PUT /mentors/{id}/availability`, `POST` (agregar), `PATCH /availability/{id}` (bloquear) y `DELETE`.
- Un solapamiento devuelve `AvailabilityOverlap` (409) **sin guardar nada parcial**.
- Web `/mentoring/availability` (`AvailabilityPanel`), horas en Bolivia (UTC−4).

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/mentoring/router.py`, `Backend/EmprendeU/src/emprendeu/modules/mentoring/service.py` |
| Web | `Frontend/emprendeu/features/mentoring/components/availability-panel.tsx`, `Frontend/emprendeu/app/(app)/mentoring/availability/page.tsx` |

## Por qué se hizo así

- Disponibilidad por intervalos en `disponibilidad_mentor` (tabla añadida al esquema en F0).

## Verificación

- `Backend/EmprendeU/tests/test_mentoring_api.py::test_disponibilidad_solapada_no_guarda_nada`, `test_disponibilidad_por_horario`

## Pendiente

- Ninguno conocido.
