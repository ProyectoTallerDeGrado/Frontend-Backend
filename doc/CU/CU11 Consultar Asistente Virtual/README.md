# CU11 — Consultar Asistente Virtual

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Emprendedor (chat en la app); coordinación/administración gestiona la base de conocimiento en la web |
| Cliente | App móvil (+ web para la base de conocimiento) |
| Fase del plan | F5 |
| **Estado** | **✅ Completado** |

## Descripción

Coach IA con RAG: responde con fragmentos de la base de conocimiento del CIE-U y muestra sus fuentes.

## Qué se hizo

- `POST /ai/chat`: busca fragmentos por similitud coseno (`pgvector`, `<=>`, índice HNSW, `vector(768)`) y los pasa al modelo de Ollama.
- Sin fragmentos relevantes responde con el mensaje de **información insuficiente** (no inventa) y sugiere agendar mentoría; también deriva temas legales/financieros.
- Si Ollama no responde: error `ai_unavailable` y **no se guarda nada** a medias.
- Conversaciones y mensajes en `conversaciones_ia` / `mensajes_ia`; sentimiento anonimizado en `analisis_sentimiento` (RF07).
- Base de conocimiento (CU31): `POST /ai/knowledge/upload` (txt, md, pdf, docx ≤ 10 MB) con estado de procesamiento; web `/knowledge`.
- Móvil: pestaña «Coach» con historial, preguntas sugeridas, fuentes y «Nueva conversación»; plazo propio de 90 s.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/ai_assistant/` (`router.py`, `service.py`, `llm.py`, `chunking.py`, `extraction.py`, `sentiment.py`) |
| Web | `Frontend/emprendeu/features/ai_assistant/` (`knowledge-screen.tsx`, `upload-knowledge-sheet.tsx`), `Frontend/emprendeu/app/(app)/knowledge/page.tsx` |
| Móvil | `Frontend/app_emprendeu/lib/features/ai_assistant/` (`assistant_usecases.dart`, `coach_screen.dart`, `message_bubble.dart`) |
| Infra | servicio `ollama-pull` en `docker-compose.yml` (perfil `ai`) |

## Por qué se hizo así

- RAG con fuentes visibles para que el emprendedor confíe en la respuesta y no se den consejos inventados.
- Ollama local: sin costos de API ni envío de datos de emprendedores a terceros.
- Sentimiento por léxico heurístico (reemplazable) para alimentar las alertas de caída de ánimo (CU13).

## Verificación

- `Backend/EmprendeU/tests/test_ai_knowledge_api.py` (RAG con dos documentos, sin fragmentos, Ollama caído, subida de archivos, sentimiento anonimizado)
- `Backend/EmprendeU/tests/test_ai_api.py` (permisos, dimensión del modelo, aislamiento entre emprendedores)
- `Frontend/app_emprendeu/test/features/ai_assistant/` (casos de uso y pantalla)

## Pendiente

- Calidad de respuestas depende del modelo y del volumen real de documentos (pendiente medir `pgvector` con datos reales).
