# CU10 — Agendar Mentoría

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Emprendedor |
| Cliente | App móvil |
| Fase del plan | F2 |
| **Estado** | **✅ Completado** |

## Descripción

El emprendedor agenda una sesión con un asesor asignado en un horario libre.

## Qué se hizo

- `GET /mentoring/booking-status` indica si la etapa permite agendar y el motivo si no.
- `GET /mentors/{id}/slots` lista turnos libres; `POST /mentoring/sessions` agenda y vuelve a comprobar el turno (`SlotUnavailable`, 409).
- El emprendedor solo ve y agenda con asesores **asignados y habilitados** (`MentorNotAssigned`).
- `POST /sessions/{id}/cancel` cancela y libera el horario.
- Móvil: flujo `/mentoring/book` → asesor → día (14 días) → turno → tema opcional → confirmar. `BookSessionUseCase` vuelve a pedir los turnos antes de agendar.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/mentoring/router.py`, `Backend/EmprendeU/src/emprendeu/modules/mentoring/service.py` |
| Móvil | `Frontend/app_emprendeu/lib/features/mentoring/` (`booking_repository_impl.dart`, `booking_usecases.dart`, `book_session_screen.dart`, `booking_providers.dart`) |

## Por qué se hizo así

- Doble verificación del turno (cliente y servidor) porque puede ocuparse entre que se lista y se confirma.
- Repositorio de agenda separado del de la cola sin conexión: agendar exige estar en línea.

## Verificación

- `Backend/EmprendeU/tests/test_mentoring_api.py::test_agendamiento_bloqueos_y_slots`, `test_emprendedor_solo_ve_y_agenda_con_asesores_asignados`, `test_cancelar_libera_el_horario`
- `Frontend/app_emprendeu/test/features/mentoring/domain/booking_usecases_test.dart`, `mentoring_screens_test.dart`

## Pendiente

- Sin notificaciones push al asesor cuando se agenda.
