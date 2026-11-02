# Hoja de ruta del backend

Cada fase se cierra con lint y tests en verde.

| Fase | Contenido | Estado |
|---|---|---|
| 0 | Cimientos: `security`, `pagination`, `logging`, errores, CORS, entorno de tests | ✅ |
| 1 | `users`: auth, usuarios, roles y matriz de permisos | ✅ |
| 2 | `audit`: `record`, `GET /audit`, export CSV, retrofit en `users` | ✅ |
| 3 | `entrepreneurs` y `ventures`: emprendedores, emprendimientos, etapas, hitos, necesidades | ✅ |
| 4 | `gamification`: retos ordenados, XP una sola vez, niveles, insignias | ✅ |
| 5 | `mentoring`: mentores, agenda, sesiones, compromisos, avances, sincronización offline | ✅ |
| 6 | `alerts` e `indicators`: parámetros, detección, KPIs del panel | ✅ |
| 7 | `ai_assistant`: RAG con Ollama, conversaciones, sentimiento | ✅ |
| 8 | `training` y `documents` | ✅ |
| 9 | Endurecimiento: límite de login, errores 500 sin fugas, secreto en producción, Docker, CI | ✅ |

## Decisiones tomadas (revisables)

- JWT de acceso único, sin refresh; recuperación de contraseña fuera de alcance.
- Niveles de XP: 0 / 200 / 400 / 700 / 1100 (`gamification/levels.py`).
- Sentimiento: índice heurístico por léxico (`ai_assistant/sentiment.py`), reemplazable.
- Búsqueda semántica: similitud coseno en Python sobre embeddings JSONB. Para miles de
  fragmentos conviene migrar a `pgvector`.
- Detección de alertas por cron externo (`alerts/jobs.py`), no por scheduler dentro de la app.

## Pendiente / siguientes mejoras

- Conectar el resto de pantallas de la web y el móvil. **Hecho:** login, registro y sesión
  en ambos (ver `Frontend/*/AGENTS.md`).
- Refresh tokens y recuperación de contraseña (requiere servicio de correo).
- Limitador de login compartido (Redis) si se despliega con varias réplicas.
- Almacén de objetos para `documents` si el volumen crece.
- Habilitar/medir `pgvector`.

**Hecho:** `EntrepreneurService.list` resuelve nombre y correo en una sola consulta
(`identities`), y un cambio de contraseña invalida los tokens anteriores
(`usuario.clave_cambiada_en`, comparada con el `iat` del JWT; la cuenta deshabilitada ya se
rechazaba por petición). Tras cambiar la contraseña el cliente debe volver a iniciar sesión.
