# CU29 — Consultar Capacitaciones

| Campo | Valor |
|---|---|
| Prioridad | Media (propuesta) |
| Actor(es) | Emprendedor |
| Cliente | App móvil |
| Fase del plan | F6 |
| **Estado** | **✅ Completado** |

## Descripción

El emprendedor ve las capacitaciones del programa, se inscribe y consulta su propia asistencia.

## Qué se hizo

- Backend: `GET /training` (lista), `GET /training/me` (ahora incluye `asistencia`) y `POST /training/{id}/enroll`.
- Móvil: feature `training` (Perfil → «Capacitaciones», ruta `/training`) con la lista **paginada** («Cargar más», 20 por página) e insignia «Inscrito», «Asististe» o «No asististe» y botón «Inscribirme» solo en las programadas.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/training/` (`repository.py: for_entrepreneur`, `schemas.py: TrainingOut.asistencia`) |
| Móvil | `Frontend/app_emprendeu/lib/features/training/` (`training_screen.dart`, `training_repository_impl.dart`) |

## Por qué se hizo así

- El repositorio combina la lista general con `/training/me` para marcar la inscripción y la asistencia.

## Verificación

- `Backend/EmprendeU/tests/test_training_documents_api.py`
- `Frontend/app_emprendeu/test/features/training/training_screen_test.dart` (incluye la paginación)

## Pendiente

- Ninguno conocido. Probar a mano en el dispositivo.
