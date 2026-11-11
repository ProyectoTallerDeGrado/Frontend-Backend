# CU12 — Gestionar Etapa del Emprendimiento

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Coordinador |
| Cliente | Web |
| Fase del plan | F3 |
| **Estado** | **✅ Completado** |

## Descripción

La coordinación avanza un emprendimiento a la siguiente etapa del programa.

## Qué se hizo

- `PUT /ventures/{id}/stage`: solo se permite la etapa activa **inmediatamente siguiente** según `etapas.orden` (sin saltos ni retrocesos, `InvalidStageTransition`).
- La etapa anterior se marca `completada` con `fecha_fin`; no se borra. Cada cambio queda en `emprendimiento_etapas` y en la auditoría.
- `GET /ventures/{id}/stages` devuelve el historial de etapas; `GET/PATCH /stages` administra el catálogo.
- Web: «Avanzar etapa» en `/ventures` (`AdvanceStageSheet`), que solo ofrece la siguiente etapa.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/ventures/service.py` (`change_stage`, `stage_history`), `Backend/EmprendeU/src/emprendeu/modules/ventures/exceptions.py` |
| Web | `Frontend/emprendeu/features/ventures/components/advance-stage-sheet.tsx`, `stage-list.tsx` |

## Por qué se hizo así

- Conservar las filas anteriores permite reconstruir el recorrido completo (historial CU19 e indicadores CU14).

## Verificación

- `Backend/EmprendeU/tests/test_audit_ventures_api.py::test_cambio_de_etapa_hitos_y_necesidades`

## Pendiente

- Ninguno conocido.
