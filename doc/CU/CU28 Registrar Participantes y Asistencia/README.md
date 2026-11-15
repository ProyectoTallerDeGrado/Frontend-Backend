# CU28 — Registrar Participantes y Asistencia

| Campo | Valor |
|---|---|
| Prioridad | Media (propuesta) |
| Actor(es) | Coordinador, asesor (consulta) |
| Cliente | Web |
| Fase del plan | F6 |
| **Estado** | **✅ Completado** |

## Descripción

La coordinación agrega participantes a una capacitación y registra si asistieron.

## Qué se hizo

- Backend: `GET/POST /training/{id}/participants` y `PATCH /training/{id}/participants/{emprendedor_id}`. Un emprendedor no se repite (409 `already_enrolled`) y una capacitación cancelada no admite participantes.
- `GET /training/{id}/participants` devuelve el `nombre` de cada participante.
- Web: detalle `/training/[id]` con la lista de participantes, **buscador de emprendedores** (nombre, correo o documento; `GET /entrepreneurs?q=`) para agregar y botones de asistió / no asistió.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/training/service.py` (`add_participant`, `set_attendance`) |
| Web | `Frontend/emprendeu/features/training/components/participants-panel.tsx`, `training-detail-screen.tsx`; página `app/(app)/training/[id]/page.tsx` |

## Por qué se hizo así

- La asistencia `null` significa «sin registrar»; así se distingue de una ausencia confirmada.
- El buscador usa `searchEntrepreneurOptions` del barrel de `entrepreneurs` (hasta 15 resultados por consulta), así que no depende de cuántos emprendedores haya.

## Verificación

- `Backend/EmprendeU/tests/test_training_documents_api.py`

## Pendiente

- Ninguno conocido. Probar a mano en el navegador.
