# EmprendeU — Guía del monorepo para agentes

> Este archivo es la **fuente de verdad de arquitectura** del proyecto.
> Todo agente (Claude Code, Codex, Cursor, Copilot, etc.) y toda persona que escriba
> código en este repositorio debe leerlo **antes** de crear archivos o carpetas.
> `CLAUDE.md` en cada proyecto solo importa su `AGENTS.md` hermano.

---

## 1. Qué es EmprendeU

Plataforma universitaria de emprendimiento. Se compone de tres aplicaciones
independientes que comparten un mismo dominio de negocio y un único contrato HTTP.

## 2. Mapa del monorepo

```
EmprendeU/
├── AGENTS.md              ← este archivo (reglas globales)
├── CLAUDE.md              ← @AGENTS.md
├── Backend/
│   └── EmprendeU/         API HTTP  · Python 3.13 + FastAPI + uv
└── Frontend/
    ├── emprendeu/         Web       · Next.js 16 (App Router) + React 19 + TS
    └── app_emprendeu/     Móvil     · Flutter / Dart 3.13
```

| App | Ruta | Stack | Arquitectura designada | Detalle |
|---|---|---|---|---|
| API | `Backend/EmprendeU` | Python 3.13, FastAPI, uvicorn, uv | **Modular (modular monolith)** | `Backend/EmprendeU/AGENTS.md` |
| Web | `Frontend/emprendeu` | Next.js 16.3.8, React 19.2.8, TypeScript 5, Tailwind v4, shadcn (`base-rhea` sobre `@base-ui/react`), lucide, zustand, pnpm 12 | **Feature-based** | `Frontend/emprendeu/AGENTS.md` |
| Móvil | `Frontend/app_emprendeu` | Flutter, Dart `^3.13.5`, flutter_lints | **Feature-first por capas** | `Frontend/app_emprendeu/AGENTS.md` |

## 3. Estado real del código (verificado el 2026-11-02)

El backend está completo. La web tiene el panel de administración conectado de punta
a punta; el móvil tiene las pantallas del emprendedor conectadas. Con la fase 7 (calidad y entrega)
el plan está cerrado: los 31 casos de uso están construidos y el tablero de §8 recoge la prueba de cada uno.

- **Backend**: todas las dependencias (ejecución y `dev`) están instaladas y
  bloqueadas en `uv.lock`. Existe la app ASGI (`emprendeu.main:create_app`), la
  configuración por entorno, el engine async, y los **modelos SQLAlchemy de las 42
  tablas del schema `cieu`** (las 38 del modelo original + `perfil_mentor`,
  `disponibilidad_mentor`, `parametros_seguimiento` y `postulaciones`) repartidos en 11 módulos. El
  esquema parte de `Backend/EmprendeU/database/EmprendeU_postgresql.sql`, hoy reemplazado por la referencia
  `database/cieu_schema_completo.sql`, y evoluciona solo con migraciones de Alembic (ver `AGENTS.md` del backend).
  **Backend completo** (fases 0 a 9): los 11 módulos exponen HTTP bajo `/api/v1`, con
  auditoría, 97 tests contra PostgreSQL real, Docker y CI. Detalle en
  `Backend/EmprendeU/AGENTS.md` §4 y `ROADMAP.md`.
- **Web**: tokens de marca, fuentes, auth conectada (cookie `httpOnly`, `proxy.ts`) y el
  **panel de administración completo** (Resumen, Usuarios, Roles y permisos, Parámetros,
  Catálogos y XP, Auditoría) conectado al backend, con permisos por rol. Mentorías (asignaciones, disponibilidad y sesiones), Emprendimientos (avanzar etapa e historial), Alertas, Dashboard, Reportes (vista previa y CSV), Emprendedores (registro con documento único), Emprendimientos (crear, editar, progreso), Base de conocimiento del coach (subir documentos y ver su estado), Admisión (con la página pública `/postular`), Capacitaciones (participantes y asistencia), Documentos y Mi cuenta.
- **Móvil**: tema, router con barra inferior, `core/` (red, errores, almacenamiento, conectividad) y
  las features `auth`, `ventures`, `gamification` (Camino), `mentoring` (compromisos y avances con cola
  sin conexión) y `home` (Inicio), todas **conectadas al backend**. Mentorías (agendar y ver las sesiones, con
  filtros por estado y periodo), historial del emprendimiento, Perfil (XP, insignias, editar el emprendimiento), hitos con evidencia y Documentos (`documents`), necesidades y dificultades, Capacitaciones (`training`), tareas y compromisos pendientes, el Coach IA (chat con fuentes) y cambio de contraseña. Tiene tests de integración opt-in contra el backend real.
- **Diseño visual**: `Frontend/emprendeu/design.md` (panel de administración) y
  `Frontend/app_emprendeu/design.md` (app del emprendedor), basados en el mockup del CIE-U.

> Por eso la arquitectura de este documento es **prescriptiva, no descriptiva**: describe
> cómo *debe* quedar el código, y es lo que hay que construir. Al implementar una parte,
> actualiza la sección correspondiente para que siga reflejando la realidad.

## 4. Reglas obligatorias para todo agente

Estas reglas no son sugerencias. Un cambio que las incumpla se considera incorrecto
aunque funcione.

1. **Leer antes de escribir.** Antes de crear cualquier archivo, lee el `AGENTS.md`
   del proyecto en el que vas a trabajar y ubica el archivo nuevo en la carpeta que
   ese documento define.
2. **Arquitectura fija por proyecto.** Backend = modular. Web = feature-based.
   Móvil = feature-first por capas. No se mezclan, no se "simplifican por ahora",
   no se introduce otro patrón sin que el usuario lo apruebe explícitamente y se
   actualice este archivo en el mismo commit.
3. **Nada de código de negocio fuera de su módulo/feature.** Ni en `app/`, ni en
   `main.py`, ni en `main.dart`, ni en carpetas `ui`/`shared`/`core`.
4. **Sin carpetas nuevas de primer nivel** dentro de `src/emprendeu/`, de la raíz web
   o de `lib/` sin que estén listadas en el `AGENTS.md` del proyecto. Si una hace
   falta de verdad: propónla, documéntala y solo entonces créala.
5. **Un módulo/feature se construye por capas, no a medias dentro de una capa.**
   Primero la persistencia completa, y los archivos HTTP (`router`, `service`,
   `repository`, `schemas`) cuando el módulo vaya de verdad a exponer endpoints: la
   capa que se toque se termina entera. Lo prohibido es dejar una capa a medio hacer
   o crear archivos vacíos para "reservar sitio".
6. **El mismo nombre de dominio en las tres apps.** Si el backend expone el módulo
   `projects`, la web tiene `features/projects` y el móvil `lib/features/projects`.
   Nombres en inglés, `snake_case` en Python/Dart, `kebab-case` en carpetas web.
7. **Dirección de dependencias hacia adentro.** Transporte (router/página/pantalla) →
   caso de uso/servicio → acceso a datos. Nunca al revés, nunca saltándose capas.
8. **Imports entre features/módulos solo por su API pública** (el barrel `index.ts`,
   el `__init__.py`, el `index.dart`). Importar un archivo interno de otra feature
   está prohibido; si lo necesitas, lo que necesitas va en `shared`/`core`.
9. **Código, nombres de archivo, identificadores y commits en inglés.** Comentarios
   y documentación (`AGENTS.md`, `README.md`) en español.
   **Excepción, la base de datos:** el esquema `cieu` está en español y es la fuente
   de verdad, así que los modelos de persistencia y sus atributos lo reflejan tal
   cual (`Emprendimiento.fecha_inicio`), igual que los DTO del móvil y los tipos de
   la web que mapean esas respuestas. Los nombres de módulo y de feature siguen en
   inglés (`ventures`, `mentoring`), y todo lo demás también.
10. **No reescribir el bloque gestionado** `<!-- BEGIN:nextjs-agent-rules -->…<!-- END -->`
    de `Frontend/emprendeu/AGENTS.md`: lo regenera `next dev`. Añade siempre debajo.
11. **Verifica, no asumas.** Antes de afirmar que algo funciona, ejecútalo
    (ver §6). Si no lo ejecutaste, dilo.
12. **Al terminar, revisa el checklist de §7.**

## 5. Contrato entre apps

- **Un solo contrato HTTP**, el del backend. Web y móvil son clientes; ninguno
  define "su propia" forma de los datos de negocio.
- **Versionado de la API**: todas las rutas cuelgan de `/api/v1`.
- **OpenAPI** (`/api/v1/openapi.json`, generado por FastAPI) es la referencia para
  los tipos del cliente web y los DTO del móvil. Si un campo cambia en el backend,
  el cambio en los dos clientes va en el mismo PR.
- **Errores**: forma única `{"error": {"code": str, "message": str, "details": object|null}}`.
- **IDs**: enteros de 64 bits (`BIGINT GENERATED BY DEFAULT AS IDENTITY`), **no UUID**:
  lo fija el esquema `cieu`. En JSON van como número; en TypeScript `number` y en
  Dart `int`.
- **Fechas**: ISO-8601 en UTC. **Paginación**:
  `?page=&page_size=` → `{"items": [...], "page": int, "page_size": int, "total": int}`.
- **Auth**: `Authorization: Bearer <JWT>`.

## 6. Comandos

```bash
# Backend  (cwd: Backend/EmprendeU)
uv sync --locked                          # instala ejecución + dev
cp .env.example .env                      # y ajustar DATABASE_URL y JWT_SECRET (>= 32 caracteres)
uv run alembic upgrade head               # crea el schema cieu y todas las tablas
uv run uvicorn emprendeu.main:app --reload --port 8000
uv run pytest                             # 97 tests (necesita PostgreSQL con pgvector)
uv run alembic check                      # el modelo y las migraciones coinciden
uv run python database/verify_schema.py --admin-url postgresql://USUARIO:CLAVE@localhost:5432/postgres
                                          # columnas, restricciones e índices: SQL de referencia vs migraciones
uv run ruff check . && uv run ruff format --check .
uv run python -m emprendeu.modules.users.cli create-admin --email ... --nombre "..."

# Web  (cwd: Frontend/emprendeu)
pnpm install
cp .env.example .env.local          # API_URL del backend
pnpm dev
pnpm build
pnpm lint
pnpm test                           # Vitest: esquemas zod y lib/ (32 tests)
E2E_BASE_URL=... E2E_API_URL=... E2E_ADMIN_EMAIL=... E2E_ADMIN_PASSWORD=... pnpm e2e
                                    # Playwright (9): login y una pantalla por rol; necesita API y web en marcha
                                    # y la API con APPLICATION_TRUST_FORWARDED_FOR=true

# Móvil  (cwd: Frontend/app_emprendeu)
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
dart run build_runner build          # tras tocar DTO freezed/json
flutter analyze
flutter test                          # 110 tests de unidad y de pantalla
flutter test --tags integration test/integration \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 \
  --dart-define=E2E_ADMIN_EMAIL=... --dart-define=E2E_ADMIN_PASSWORD=...
                                      # contra el backend real (10.0.2.2 en Android, 127.0.0.1 en iOS)
```

> El backend necesita un PostgreSQL 15+ accesible en `DATABASE_URL`; el
> `README.md` del backend trae el comando de Docker para levantar uno de
> desarrollo. Los paquetes del móvil ya están instalados (`flutter pub get`).
> Para correr los tests del backend hace falta PostgreSQL arriba y `JWT_SECRET` en `.env`.

## 7. Checklist antes de dar por terminado un cambio

- [ ] Cada archivo nuevo está en la carpeta que manda el `AGENTS.md` del proyecto.
- [ ] No hay imports a archivos internos de otra feature/módulo.
- [ ] La dirección de dependencias se respeta (§4.7).
- [ ] Si el cambio toca el contrato HTTP, los tres proyectos quedan alineados.
- [ ] Lint y tests del proyecto tocado pasan, y lo reportas con su salida real.
- [ ] Si introdujiste una feature/módulo, lo añadiste a la tabla de features del
      `AGENTS.md` correspondiente.

## 8. Regla de alcance y tablero de casos de uso

**Regla de alcance.** Un caso de uso (CU) solo cuenta como completo si cumple los **cuatro criterios**:
(1) endpoint con una prueba que pasa, (2) pantalla en el cliente correcto (la **web** es para todos los
actores salvo el emprendedor; la **app móvil**, solo para el emprendedor), (3) datos verificados contra el
esquema y las migraciones (`verify_schema.py` sin diferencias) y (4) flujo de punta a punta probado. Ningún
CU se marca sin la salida real de sus pruebas. Lo que no está en el tablero no se construye sin que el
usuario lo apruebe y se registre aquí. **Una sola réplica del backend:** los limitadores de intentos
(login y formulario público) viven en memoria; con más réplicas hay que moverlos a un almacén compartido.

Prueba de cada criterio: **B** = test de la API (`Backend/EmprendeU/tests/`), **W** = pantalla web,
**M** = pantalla móvil, **E** = flujo de punta a punta (`test_roles_flow_api.py` por rol; `e2e/roles.spec.ts`
con Playwright en la web; `test/integration/*` en el móvil contra la API real).

| CU | Caso de uso | Cliente | B (backend) | Pantalla | E (extremo a extremo) |
|---|---|---|---|---|---|
| 01 | Iniciar sesión | web y móvil | `test_auth_api` | web `/login`; móvil `auth` | Playwright (login) y `auth_backend_test` |
| 02 | Gestionar usuarios | web | `test_users_admin_api` | web `/users` | flujo administrador |
| 03 | Roles y permisos | web | `test_users_admin_api` | web `/roles` | flujo administrador |
| 04 | Registrar emprendedor | web | `test_entrepreneurs_api` (incluye documento único en la base) | web `/entrepreneurs` | flujo coordinador |
| 05 | Gestionar emprendimiento | web y móvil | `test_audit_ventures_api`, `test_entrepreneurs_api` | web `/ventures`; móvil `ventures` | flujo coordinador y emprendedor |
| 06 | Progreso gamificado | web y móvil | `test_gamification_api` | web `/ventures/[id]/progress`; móvil Camino | flujo emprendedor |
| 07 | Cumplir un reto | móvil | `test_gamification_api` | móvil Camino | `home_backend_test` |
| 08 | XP e insignias | móvil | `test_gamification_api` | móvil Perfil | `home_backend_test` |
| 09 | Asignar asesor | web | `test_mentoring_api` | web `/mentoring/assignments` | flujo coordinador |
| 10 | Agendar mentoría | móvil | `test_mentoring_api` | móvil `/mentoring/book` | flujo emprendedor |
| 11 | Asistente virtual | móvil | `test_ai_api` | móvil Coach | flujo emprendedor (IA simulada) |
| 12 | Gestionar etapa | web | `test_audit_ventures_api` | web `/ventures` | flujo coordinador |
| 13 | Gestionar alertas | web | `test_alerts_indicators_api` | web `/alerts` | flujo asesor |
| 14 | Dashboard ejecutivo | web | `test_dashboard_reports_api` | web `/dashboard` | flujo coordinador |
| 15 | Disponibilidad del mentor | web | `test_mentoring_api` | web `/mentoring/availability` | flujo asesor |
| 16 | Registrar sesión | web | `test_mentoring_api` | web `/mentoring/sessions` | flujo asesor |
| 17 | Recomendaciones | web | `test_mentoring_api` | web `/mentoring/sessions` | flujo asesor |
| 18 | Compromisos | web | `test_mentoring_api` | web `/mentoring/sessions` | flujo asesor |
| 19 | Historial del emprendimiento | web y móvil | `test_mentoring_api` | web `/ventures/[id]/history`; móvil `/mentoring/history` | flujo emprendedor |
| 20 | Avances e hitos | móvil | `test_audit_ventures_api`, `test_mentoring_api` | móvil hitos y evidencia | `home_backend_test` |
| 21 | Generar reportes | web | `test_dashboard_reports_api` | web `/reports` | flujo coordinador |
| 22 | Tareas pendientes | móvil | `test_phase6_api` | móvil Inicio | `admission_backend_test` |
| 23 | Mentorías programadas | web y móvil | `test_mentoring_api` | web `/mentoring/sessions`; móvil Mentorías | flujo asesor y emprendedor |
| 24 | Necesidades y dificultades | móvil | `test_phase6_api` | móvil `/venture/needs` | `admission_backend_test` |
| 25 | Parámetros de seguimiento | web | `test_alerts_indicators_api` | web `/settings/tracking` | flujo administrador |
| 26 | Gestionar admisión | web | `test_admissions_api` | web `/admissions` y `/postular` | Playwright (postulación) y `admission_backend_test` |
| 27 | Gestionar capacitaciones | web | `test_training_documents_api`, `test_phase6_api` | web `/training` | flujo coordinador |
| 28 | Participantes y asistencia | web | `test_phase6_api` | web `/training/[id]/participants` | flujo coordinador |
| 29 | Consultar capacitaciones | móvil | `test_phase6_api` | móvil `/training` | flujo emprendedor |
| 30 | Gestionar documentos | web y móvil | `test_training_documents_api`, `test_phase6_api` | web `/documents`; móvil `/documents` | flujo emprendedor |
| 31 | Base de conocimiento | web | `test_ai_knowledge_api` | web `/knowledge` | flujo coordinador |

> La columna de pantalla usa los nombres de ruta de cada app; ante la duda, manda el `AGENTS.md` del cliente.
> Resultado de la verificación final (2026-11-02): backend 97 pruebas, web 32 (Vitest) + 9 (Playwright),
> móvil 110 de unidad y 4 de integración contra la API real (1 opcional omitida); `verify_schema.py` sin
> diferencias (263 columnas, 142 restricciones, 121 índices). La auditoría completa está en
> [`doc/AUDITORIA_FINAL.md`](doc/AUDITORIA_FINAL.md).
