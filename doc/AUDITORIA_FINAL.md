# Auditoría final de EmprendeU (fase 7)

Fecha: 2026-11-02 · Rama `feat/fase-7-calidad` · Base de comparación: el plan `doc/Plan de finalización EmprendeU para el agente.pdf`.

## Resumen

1. Los 31 casos de uso están construidos y cada uno tiene su prueba y su pantalla en el cliente correcto (tablero en `AGENTS.md` §8). Los 22 de alcance (17 de prioridad alta + CU07, CU15, CU21, CU23, CU26) están cerrados con los cuatro criterios.
2. Todas las pruebas automáticas pasan: backend 97, web 32 (Vitest) + 9 (Playwright), móvil 110 + 4 de integración contra la API real.
3. El esquema migrado coincide con `cieu_schema_completo.sql`: `verify_schema.py` sin diferencias (263 columnas, 142 restricciones, 121 índices) y `alembic check` limpio.
4. **Sin hallazgos críticos ni altos abiertos.** Esta auditoría encontró y corrigió dos críticos de dependencias (Next.js) y un alto de memoria (limitador); quedan 2 avisos menores solo de herramientas de desarrollo.
5. Lo que no se pudo verificar sin una persona: el recorrido manual en un emulador o teléfono y el cuerpo del modelo de IA real (Ollama) con documentos de la institución.

## Verificación ejecutada (salida real, 2026-11-02)

| Comprobación | Resultado |
|---|---|
| `ruff check` / `ruff format --check` (backend) | sin errores |
| `alembic check` | «No new upgrade operations detected» |
| `pytest` (PostgreSQL 17 + pgvector real) | **97 passed** |
| `verify_schema.py` | RESULTADO: sin diferencias (263 / 142 / 121) |
| `pnpm lint`, `tsc --noEmit`, `pnpm build` | sin errores |
| `pnpm test` (Vitest) | 32 passed (7 archivos) |
| `pnpm e2e` (Playwright, Chromium, API y web reales) | 9 passed |
| `flutter analyze` | No issues found |
| `flutter test` | 110 passed (+ 4 de integración omitidas sin API) |
| `flutter test --tags integration` contra la API real | 4 passed, 1 omitida (rechazo de cuenta de personal: pide `STAFF_EMAIL`/`STAFF_PASSWORD`) |
| `pnpm audit --prod` | No known vulnerabilities |
| `pip-audit` (dependencias de ejecución del backend) | No known vulnerabilities |
| Búsqueda de secretos en lo versionado | limpia (el `.env` no se versiona) |
| `docker compose up` desde cero (proyecto aislado) | base creada solo con migraciones, API sana |
| Variables de `Settings` documentadas en `.env.example` | 27 de 27 |

## Casos de uso

Ver el tablero completo en [`AGENTS.md`](../AGENTS.md) §8 (CU01 a CU31, con prueba de backend, pantalla y flujo de punta a punta). Estado: **31 de 31 construidos**; cada fila cita la prueba que lo cubre. Un flujo completo por rol vive en `Backend/EmprendeU/tests/test_roles_flow_api.py` (administrador, coordinador, asesor, emprendedor).

## Problemas encontrados

### Críticos
| # | Hallazgo | Estado |
|---|---|---|
| C1 | Next.js 16.3.8: ejecución remota de código sin sesión (optimización de imágenes con SVG y `use cache`), afecta a `>=16.0.0 <=16.4.0` | **Corregido**: actualizado a 16.4.4; `pnpm audit --prod` limpio; lint, tipos, build, Vitest y Playwright verdes tras el cambio |

### Altos
| # | Hallazgo | Estado |
|---|---|---|
| A1 | Next.js: denegación de servicio en Server Actions (mismo rango) | **Corregido** con C1 |
| A2 | `SlidingWindowLimiter` guardaba una entrada por clave para siempre: rotar IP o correo (más aún con `APPLICATION_TRUST_FORWARDED_FOR=true`) hacía crecer la memoria sin límite | **Corregido**: descarta claves vencidas (barrida cada 256 intentos) y consultar ya no crea entradas; prueba `test_el_limitador_no_acumula_claves_vencidas` |
| A3 | `shadcn` (CLI de desarrollo) estaba en `dependencies` y arrastraba 7 avisos altos a producción | **Corregido**: movido a `devDependencies` |

### Medios
| # | Hallazgo | Estado |
|---|---|---|
| M1 | `opentelemetry-api` 1.45.0 con aviso CVE-2026-114603 (viene con FastAPI) | **Corregido**: `uv.lock` fija 1.45.2 |
| M2 | Una prueba de documentos contaba los PDF de una carpeta compartida por toda la sesión y fallaba según el orden | **Corregido**: compara contra lo que había antes |
| M3 | Limitadores en memoria: válidos para **una** réplica | **Aceptado por el usuario** (una sola réplica). Documentado en `AGENTS.md` y `.env.example` |

### Bajos / informativos
| # | Hallazgo | Estado |
|---|---|---|
| B1 | `pnpm audit` completo: 1 moderado (`minimatch` vía `eslint-config-next`) y 1 bajo (`deepmerge` vía `shadcn`); ambos solo en herramientas de desarrollo, no llegan a producción | Abierto, sin acción (esperar actualización de las herramientas) |
| B2 | Las pruebas de Playwright y de integración del móvil no corren en cada cambio (necesitan todo levantado): están en el flujo manual `e2e.yml` | Aceptado |
| B3 | El umbral de similitud del coach (0.65) se calibró con una muestra pequeña | Ajustar con documentos reales (`AI_MIN_SIMILARITY`) |
| B4 | Cambio de contraseña en el móvil y flujos de pantalla no probados a mano en un dispositivo | Pendiente de una persona con emulador |

## Lista de entrega

- [x] Sin secretos en git (`.env`, `e2e/.users.json`, `uploads/` fuera de versión).
- [x] Todas las variables de entorno documentadas en `.env.example` (27 de 27).
- [x] `docker compose up` desde cero crea la base solo con migraciones y la API arranca.
- [x] Base creada por migraciones = esquema de referencia (`verify_schema.py`).
- [x] Documentación al día: `AGENTS.md` (raíz, backend, web, móvil), `ROADMAP.md`, tablero de 31 casos.
- [x] Lint y pruebas de cada proyecto en verde, con salida real (tabla de arriba).

## Plan priorizado de lo que queda

1. (Media) Recorrido manual de la app en un emulador/teléfono y revisión visual contra `design.md`.
2. (Media) Probar el coach con los documentos reales del CIE-U y reajustar `AI_MIN_SIMILARITY`.
3. (Baja) Si se despliega más de una réplica, mover los limitadores a Redis.
4. (Baja) Revisar `B1` cuando salgan nuevas versiones de `eslint-config-next` y `shadcn`.

## Preguntas abiertas para el usuario

- ¿Se recupera el cambio que había en `Backend/EmprendeU/database/EmprendeU_postgresql.sql`? Se revirtió; sigue en el commit `e781884`.
- ¿Qué IP por defecto debe llevar `app_config.dart` en la rama principal (hoy una IP de LAN)? Se dejó sin tocar.
