# Asistente de ayuda (chatbot) y tutorial guiado — Panel web EmprendeU

> Fecha: 2026-11-16 · Rama: `feat/mejorUIUX`
> Alcance: **panel web** (`Frontend/emprendeu`) y **backend** (`Backend/EmprendeU`). La app móvil no cambia.

## 1. Objetivo

1. **Chatbot de ayuda**: un botón flotante abajo a la derecha, en todas las pantallas del panel, que abre un chat
   donde el usuario pregunta **cómo usar el sistema** (dónde está cada cosa, qué puede hacer y los pasos).
   Responde con IA de **Google Gemini** (capa gratuita, ~50 llamadas al día).
2. **Tutorial guiado**: la **primera vez** que un usuario entra al panel, un recorrido resalta cada zona de la
   pantalla (menú, grupos del menú, su cuenta y el botón de ayuda) y un globo de texto explica qué puede y debe hacer ahí.

## 2. Decisiones

| Tema | Decisión | Motivo |
|---|---|---|
| Proveedor de IA | Google Gemini (`gemini-2.5-flash`) por API REST desde el **backend** | La clave nunca llega al navegador; el panel ya llama al backend por server actions. |
| Límite gratuito | Contador diario en la base (`ayuda_uso_diario`), tope `HELP_DAILY_LIMIT=50` | Sobrevive reinicios y varias instancias; el incremento es atómico. |
| Sin IA disponible | Respuesta de una **guía escrita** (`help_guide.py`) elegida por palabras clave | El chat nunca queda mudo: sin clave, sin cupo o con Gemini caído sigue ayudando. |
| Qué sabe la IA | Solo la guía del sistema, **filtrada por el rol** y con la **pantalla actual** | No inventa pantallas y no ofrece lo que el rol no puede hacer. |
| Conversación | No se guarda en el servidor; el historial (6 turnos) lo envía el navegador | Es ayuda de uso, no el coach; sin datos personales que guardar. |
| "Ya vio el tutorial" | Columna `usuario.tutorial_completado_at` en la base | Funciona en cualquier navegador o equipo. |
| Librería de tutorial | Propia (sin dependencias nuevas) | Control total del diseño, accesibilidad y textos por rol. |
| Ubicación (arquitectura) | Chat en `ai_assistant` (backend y web); tutorial en `users`/`auth` | Respeta los dominios existentes (regla global §4.6); no se crean features nuevas. |

## 3. Fases

### Fase 1 — Backend: Gemini y endpoint de ayuda ✅

- `core/config.py` y `.env.example`: `GEMINI_API_KEY`, `GEMINI_MODEL`, `GEMINI_TIMEOUT_SECONDS`, `HELP_DAILY_LIMIT`.
  También pasan al contenedor `api` en `docker-compose.yml`.
- `modules/ai_assistant/gemini.py`: `GeminiClient` (`generateContent`, `systemInstruction`, historial con roles
  `user`/`model`, temperatura 0,3, sin "thinking" para ahorrar tokens) detrás del protocolo `HelpLLM`.
- `modules/ai_assistant/help_guide.py`: guía del panel, una entrada por pantalla (ruta, roles que la ven,
  resumen, pasos y palabras clave). `guide_for(rol)` arma el contexto de la IA. `faq_answer(...)` es la respuesta
  sin IA: puntúa cada tema por raíz de palabra (`asigno` ~ `asignar`) y da más peso a las palabras que distinguen
  un tema. Si nada coincide, usa la pantalla actual.
- `modules/ai_assistant/help_service.py`: `HelpService.answer` arma el prompt (rol, ruta y guía) y reserva una
  llamada del cupo diario. Si Gemini falla, devuelve el cupo y responde con la guía.
- `models.py` + `repository.py`: tabla `ayuda_uso_diario(fecha PK, llamadas)` y `HelpUsageRepository`
  (`INSERT … ON CONFLICT DO UPDATE … WHERE llamadas < límite RETURNING`).
- `router.py`: **`POST /api/v1/ai/help`** para cualquier usuario autenticado.

```jsonc
// Petición
{ "mensaje": "¿Cómo registro una sesión?", "ruta": "/mentoring/sessions",
  "historial": [{ "rol": "user", "texto": "hola" }, { "rol": "assistant", "texto": "¡Hola!" }] }
// Respuesta
{ "respuesta": "…", "origen": "ia" | "guia", "restantes_hoy": 49 | null }
```

### Fase 2 — Backend: bandera del tutorial ✅

- `usuario.tutorial_completado_at TIMESTAMPTZ NULL`, que sale en `GET /auth/me` y en el login.
- **`POST /api/v1/auth/me/tutorial`** lo marca como completado. **`DELETE`** lo reinicia, para que vuelva a
  aparecer en el próximo ingreso.
- Migración **`509235c3a151`**, que crea la columna y la tabla `ayuda_uso_diario`. Los usuarios que ya existían
  quedan en `NULL`, así que verán el tutorial una vez.

### Fase 3 — Web: chatbot flotante ✅

- `features/ai_assistant/components/help-chat.tsx` (`HelpChat`):
  - Botón redondo fijo abajo a la derecha que abre el panel de chat.
  - Saludo inicial y 3 preguntas sugeridas según la pantalla (`help-suggestions.ts`).
  - Indicador de "escribiendo" y Markdown mínimo (negritas y listas, sin HTML).
  - Aviso cuando responde la guía sin IA.
  - Botones para borrar la conversación y para cerrar (también con `Esc`).
  - Al pie, **"Ver el tutorial del sistema"**.
- `server/actions.ts` → `askHelpAction` (server action con `authedFetch` y validación zod de la respuesta).
- `stores/help-chat-store.ts` (zustand): la conversación se conserva al navegar entre pantallas.
- El layout de `(app)` lo monta en la nueva ranura `overlays` de `AppShell`. Los avisos (`Toaster`) subieron para
  no tapar el botón.
- Animaciones `help-chat-in` y `help-dot` en `globals.css`. Respetan "reducir movimiento".

### Fase 4 — Web: tutorial guiado ✅

- `features/auth/components/tour/guided-tour.tsx` (`GuidedTour`):
  - Oscurece la pantalla y recorta el elemento del paso con un borde resaltado.
  - El recorte se desliza de un elemento al siguiente.
  - El globo se ubica a la derecha, abajo, arriba o a la izquierda sin salirse de la ventana, y se reubica al hacer
    scroll o cambiar el tamaño.
  - Controles: Saltar, Anterior, Siguiente y Empezar, con un indicador de pasos.
  - Teclado: `←` y `→` cambian de paso y `Esc` lo salta. Es un `role="dialog"` con el foco en el botón principal.
- `tour-steps.ts` arma los pasos en el servidor, con el menú **ya filtrado por los permisos** del usuario:
  1. Bienvenida con su nombre.
  2. El menú.
  3. Un paso por cada grupo visible (Inicio, Programa, Acompañamiento, Configuración), con lo que se hace en cada pantalla.
  4. Mi cuenta.
  5. El botón de ayuda.
  6. Cierre.
- Los elementos se marcan con `data-tour` en el menú (`sidebar-nav.tsx`) y en la tarjeta de usuario y el botón de
  ayuda (`app-shell.tsx`).
- En el celular, con el menú cerrado, el globo aparece centrado y el texto indica dónde abrir el menú.
- Arranca solo si `tutorial_completado_at` es `null`. Al terminar o saltarlo, `completeTutorialAction` llama a
  `POST /auth/me/tutorial`.
- `RestartTourButton` lo repite. Está en el pie del chat y en **Mi cuenta**.

### Fase 5 — Documentación ✅

- Este documento.
- `AGENTS.md` raíz §3 (estado).
- `Backend/EmprendeU/AGENTS.md`: tabla nueva, endpoints y convenciones del asistente y del tutorial.
- `Frontend/emprendeu/AGENTS.md`: cómo está armado el chat y el tutorial.

## 4. Archivos

**Backend** (`Backend/EmprendeU`)

| Archivo | Cambio |
|---|---|
| `src/emprendeu/core/config.py`, `.env.example`, `docker-compose.yml` | Variables de Gemini y cupo diario |
| `src/emprendeu/modules/ai_assistant/gemini.py` | **Nuevo**: cliente Gemini (`HelpLLM`, `get_help_llm`) |
| `src/emprendeu/modules/ai_assistant/help_guide.py` | **Nuevo**: guía del sistema y respuestas sin IA |
| `src/emprendeu/modules/ai_assistant/help_service.py` | **Nuevo**: lógica del asistente de ayuda |
| `src/emprendeu/modules/ai_assistant/{models,repository,schemas,router,__init__}.py` | Tabla y repositorio del cupo, esquemas `HelpRequest`/`HelpReply`, `POST /ai/help` |
| `src/emprendeu/modules/users/{models,schemas,repository,service,router}.py` | `tutorial_completado_at` y `POST/DELETE /auth/me/tutorial` |
| `src/emprendeu/db/migrations/versions/509235c3a151_*.py` | **Nueva** migración |
| `tests/test_help_api.py`, `src/emprendeu/modules/ai_assistant/tests/test_help_guide.py`, `tests/fakes.py`, `conftest.py` | Tests y doble `FakeHelpLLM` (los tests nunca llaman a Gemini) |

**Web** (`Frontend/emprendeu`)

| Archivo | Cambio |
|---|---|
| `features/ai_assistant/components/help-chat.tsx`, `help-suggestions.ts` (+ test) | **Nuevos**: chat flotante y sugerencias |
| `features/ai_assistant/stores/help-chat-store.ts` | **Nuevo**: estado del chat |
| `features/ai_assistant/{server/actions.ts,schemas/ai-schemas.ts,types.ts,index.ts}` | `askHelpAction`, esquema y tipos |
| `features/auth/components/tour/{guided-tour.tsx,restart-tour-button.tsx,tour-steps.ts}` (+ test) | **Nuevos**: tutorial guiado |
| `features/auth/stores/tour-store.ts` | **Nuevo**: estado del tutorial |
| `features/auth/{server/actions.ts,schemas/api-schemas.ts,components/account-view.tsx,index.ts}` | `completeTutorialAction`, campo en `/auth/me` y botón en Mi cuenta |
| `app/(app)/layout.tsx`, `components/layout/{app-shell,sidebar-nav,toaster}.tsx`, `app/globals.css` | Montaje, marcas `data-tour`, posición de avisos y animaciones |

## 5. Configuración

1. Crea una clave gratuita en **Google AI Studio**: <https://aistudio.google.com/apikey>.
2. En `Backend/EmprendeU/.env`:
   ```env
   GEMINI_API_KEY=tu-clave
   GEMINI_MODEL=gemini-2.5-flash
   HELP_DAILY_LIMIT=50
   ```
3. Aplica la migración: `uv run alembic upgrade head`.
4. Reinicia la API. Sin `GEMINI_API_KEY` todo funciona igual, pero el chat responde con la guía sin IA.

> Si la capa gratuita de tu cuenta tiene otro límite diario, ajusta `HELP_DAILY_LIMIT` a ese número.
> El contador se reinicia cada día a las 00:00 UTC (20:00 en Bolivia).

## 6. Verificación (salida real)

| Comando | Resultado |
|---|---|
| `uv run ruff check . && uv run ruff format --check .` | `All checks passed!` · `165 files already formatted` |
| `uv run alembic upgrade head` + `uv run alembic check` | migración `588bb2ff36ff -> 509235c3a151` aplicada · `No new upgrade operations detected.` |
| `uv run pytest` (suite completa del backend) | `141 passed` (incluye los 16 nuevos de ayuda y tutorial) |
| `uv run pytest src/emprendeu/modules/ai_assistant/tests tests/test_help_api.py` | `16 passed` |
| `pnpm lint` | sin errores |
| `pnpm test` | `30 passed` (7 archivos, incluye `help-suggestions.test.ts` y `tour-steps.test.ts`) |
| `pnpm build` | compila |

**Prueba manual en navegador** (Playwright con Chromium, backend y web levantados, cuenta demo `asesor@emprendeu.bo`):

- Al entrar por primera vez aparece la bienvenida. El recorrido resalta el menú y los grupos "Programa" y
  "Acompañamiento" (solo lo que ve un asesor), luego "Mi cuenta" y el botón de ayuda.
- Al terminar y recargar, el tutorial **no** vuelve a aparecer.
- El chat abre, ofrece sugerencias y responde "¿Cómo registro una sesión realizada?" con los pasos de **Sesiones**.
- "Ver el tutorial del sistema" cierra el chat y vuelve a lanzar el recorrido.
- En 390 px de ancho el globo aparece centrado y el botón de ayuda queda accesible.
- `curl POST /api/v1/ai/help` sin clave de Gemini devolvió `origen: "guia"`. Así se detectó y corrigió una
  coincidencia errónea: "asigno un asesor" iba a Emprendimientos y ahora va a Asignaciones (cubierto por test).

**Pendiente de probar con la clave real**: la respuesta de Gemini (`origen: "ia"`) solo se probó con el doble de
tests, porque en este entorno no hay `GEMINI_API_KEY`. Con la clave configurada, basta abrir el chat y preguntar.

## 7. Mantenimiento

- **Al agregar o cambiar una pantalla del menú** (`app/(app)/layout.tsx`, `NAV`), actualiza también:
  - su tema en `Backend/EmprendeU/src/emprendeu/modules/ai_assistant/help_guide.py`;
  - su texto en `SCREEN_TEXT` de `Frontend/emprendeu/features/auth/components/tour/tour-steps.ts`;
  - si aplica, sus preguntas en `help-suggestions.ts`.
- Para volver a mostrarle el tutorial a alguien: `DELETE /api/v1/auth/me/tutorial` con su sesión, o el botón
  "Ver el tutorial del sistema".

## 8. Tutorial guiado en la app móvil

El emprendedor ve un recorrido de primer ingreso en la app (`Frontend/app_emprendeu`), con la misma bandera del
backend que la web (`usuario.tutorial_completado_at`): se ve una vez por cuenta, en cualquier dispositivo.

- **Qué hace:** oscurece la pantalla, resalta un elemento real (barra inferior, progreso, próximo reto, campana,
  Camino, Mentorías, Coach, Perfil) y lo explica en un globo. Al avanzar cambia de pestaña solo. Controles: Saltar,
  Anterior, Siguiente y Empezar; el botón «atrás» de Android lo salta.
- **Cuándo sale:** ~0,7 s después de entrar si `GET /auth/me` trae `tutorial_completado_at = null`. Al terminar o saltar
  llama a `POST /auth/me/tutorial` (si falla, vuelve a salir en el próximo ingreso).
- **Repetirlo:** Perfil → «Ver el tutorial de la app» (local, no toca el backend hasta terminar).
  Para forzarlo en el próximo ingreso: `DELETE /api/v1/auth/me/tutorial`.
- **Código** (`lib/features/auth/presentation/tour/`): `tour_steps.dart` (pasos y pestañas), `tour_controller.dart`
  (estado), `tour_targets.dart` (`TourTarget(id:, child:)` registra el `GlobalKey` de cada elemento) y
  `guided_tour.dart` (overlay con recorte animado y globo). `AppShell` lo monta encima de la barra inferior.
- **Mantenimiento:** al añadir una pantalla o sección importante, agrega su paso en `buildTourSteps` y envuelve el
  elemento con `TourTarget`. Si el elemento no existe (p. ej. aún carga), el globo sale centrado.
- **Pruebas:** `test/features/auth/presentation/guided_tour_test.dart`. El usuario de prueba `entrepreneur` ya tiene el
  tutorial visto para que no tape las demás pantallas.
