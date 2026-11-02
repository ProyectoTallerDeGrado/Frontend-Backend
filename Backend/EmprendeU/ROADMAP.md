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

## Plan de finalización (`doc/Plan de finalización EmprendeU para el agente.pdf`)

| Fase | Contenido | Estado |
|---|---|---|
| F7 | Calidad y entrega: Vitest y Playwright en la web, integración del móvil contra la API real, un flujo de punta a punta por rol (`test_roles_flow_api.py`), documento de identidad único en la base, verificación final del esquema (`verify_schema.py`, sin diferencias), CI de web y móvil, `.env.example` completo, auditoría final (`doc/AUDITORIA_FINAL.md`) y tablero de los 31 casos en `AGENTS.md` §8 | ✅ (verificado el 2026-11-02) |
| F6 | Admisión y casos restantes: postulaciones con formulario público, admisión en una sola transacción y decisión definitiva (CU26), capacitaciones publicadas con participantes y asistencia (CU27 a CU29), documentos para coordinación, asesor asignado y emprendedor (CU30), necesidades y dificultades (CU24) y tareas pendientes (CU22), en backend, web y móvil | ✅ |
| F5 | Asistente IA con RAG: base de conocimiento con estado de procesamiento y subida de archivos txt/md/pdf/docx (CU31), coach con fuentes, mensaje de información insuficiente, error claro sin guardar nada si Ollama cae y sentimiento anonimizado (CU11), con servicio `ollama-pull` en el compose, en backend, web y móvil | ✅ |
| F4 | Emprendimientos, progreso e hitos: registrar emprendedor con documento único (CU04), emprendimiento propio con campos reservados a la coordinación (CU05), progreso gamificado visible al personal (CU06), cumplir retos (CU07), XP e insignias en el Perfil (CU08) y hitos con evidencia en `documentos.hitoid` (CU20), en backend, web y móvil | ✅ |
| F3 | Seguimiento, alertas y dashboard: avance de etapa solo a la siguiente (CU12), alertas revisada/atendida con `atendida_por_usuarioid` y job periódico (CU13), dashboard con filtros de periodo y etapa (CU14), historial del emprendimiento (CU19), reportes con vista previa y CSV (CU21) y parámetros validados con bitácora (CU25), en backend, web y móvil | ✅ |
| F2 | Mentorías: asignar asesor habilitado (CU09), disponibilidad por horario (CU15), agendar con asesor asignado (CU10), registrar sesión (CU16), recomendaciones (CU17), compromisos con responsable válido (CU18) y mentorías programadas por estado y periodo (CU23), en backend, web y móvil | ✅ |
| F1 | Seguridad y cuentas: invalidar tokens al cambiar la contraseña (`password_changed_at`), cambio de contraseña en web y móvil, `JWT_SECRET` validado en todos los entornos, credenciales de compose y CI por variables, CORS por variable | ✅ |
| F0 | Esquema alineado con `cieu_schema_completo.sql` (pgvector, postulaciones, compromisos, disponibilidad por intervalos, parámetros clave-valor); migraciones fuera del arranque del contenedor | ✅ |

## Decisiones tomadas (revisables)

- JWT de acceso único, sin refresh; recuperación de contraseña fuera de alcance.
- Niveles de XP: 0 / 200 / 400 / 700 / 1100 (`gamification/levels.py`).
- Sentimiento: índice heurístico por léxico (`ai_assistant/sentiment.py`), reemplazable.
- Búsqueda semántica: distancia coseno con `pgvector` (`vector(768)`, índice HNSW).
- Detección de alertas por cron externo (`alerts/jobs.py`), no por scheduler dentro de la app.

## Pendiente / siguientes mejoras

- Conectar el resto de pantallas de la web y el móvil. **Hecho:** login, registro y sesión
  en ambos (ver `Frontend/*/AGENTS.md`).
- Refresh tokens y recuperación de contraseña (requiere servicio de correo).
- Limitador de login compartido (Redis) si se despliega con varias réplicas.
- Almacén de objetos para `documents` si el volumen crece.
- Habilitar/medir `pgvector` con volumen real.

**Hecho:** `EntrepreneurService.list` resuelve nombre y correo en una sola consulta
(`identities`), y un cambio de contraseña invalida los tokens anteriores
(`usuario.password_changed_at`, ver F1; la cuenta deshabilitada ya se rechazaba por petición).
Tras cambiar la contraseña el servidor devuelve una sesión nueva a quien la cambió.
