# CU31 — Gestionar Base de Conocimiento

| Campo | Valor |
|---|---|
| Prioridad | Media (propuesta) |
| Actor(es) | Coordinador, administrador |
| Cliente | Web |
| Fase del plan | F5 |
| **Estado** | **✅ Completado** |

## Descripción

La coordinación sube documentos que alimentan al Coach IA y ve su estado de procesamiento.

## Qué se hizo

- Backend: `GET/POST /ai/knowledge`, `POST /ai/knowledge/upload` (txt, md, pdf, docx), `DELETE /ai/knowledge/{id}` (desactiva). El documento pasa por `procesando` → `activo` o `error`.
- Web: `/knowledge` con la lista y su estado, hoja para subir y botón para desactivar.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/ai_assistant/` (`service.py`, `chunking.py`, `extraction.py`) |
| Web | `Frontend/emprendeu/features/ai_assistant/components/knowledge-screen.tsx`, `upload-knowledge-sheet.tsx`; página `app/(app)/knowledge/page.tsx` |

## Por qué se hizo así

- Solo los documentos `activo` alimentan al coach; si el modelo de embeddings cae, el documento queda en `error` y no se pierde el intento.

## Verificación

- `Backend/EmprendeU/tests/test_ai_knowledge_api.py`

## Pendiente

- Probar a mano con Ollama levantado.
