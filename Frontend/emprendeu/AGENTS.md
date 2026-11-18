<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

---

# Web EmprendeU — Arquitectura feature-based

> Lee antes `../../AGENTS.md` (reglas globales del monorepo).
> Este documento es **prescriptivo**: define cómo debe quedar la web.
> El bloque de arriba lo gestiona `next dev`; **no lo edites ni lo borres**, escribe debajo.

---

## 1. Stack real (`package.json`, verificado)

| Pieza | Versión | Notas |
|---|---|---|
| Next.js | **16.3.8** | App Router. Ojo: en Next 16 el middleware se llama **Proxy** (`proxy.ts`). Consulta siempre `node_modules/next/dist/docs/` antes de escribir, como pide el bloque de arriba. |
| React / React DOM | 19.2.8 | Server Components por defecto |
| TypeScript | 5 | `strict: true`, alias `@/*` → raíz del proyecto |
| Tailwind CSS | v4 | vía `@tailwindcss/postcss`; sin `tailwind.config` — los tokens van en `app/globals.css` |
| shadcn | 4.x, estilo `base-rhea` | genera sobre **`@base-ui/react`**, no sobre Radix. `rsc: true` |
| Iconos | `lucide-react` | |
| Estado cliente | **`zustand`** 5 | |
| Utilidad `cn` | paquete `cn`, reexportado en `lib/utils.ts` | |
| Gestor | **pnpm** 12.9.1 | usa `pnpm`, nunca `npm`/`yarn` |

`zod` (validación de `features/auth`) y `server-only` ya están instalados. Sin librería de datos ni de formularios todavía. Pruebas: `vitest` y `@playwright/test`.
Si el estado de servidor lo justifica, `@tanstack/react-query` **solo** para datos
consumidos desde componentes cliente.

> **Diseño visual:** tokens, pantallas y componentes del panel de administración
> están en [`design.md`](design.md). Léelo antes de escribir cualquier UI.

> Estado real hoy: **panel de administración completo y conectado al backend**:
> Resumen (`/`), Usuarios (`/users`), Roles y permisos (`/roles`), Parámetros
> (`/settings/tracking`), Catálogos y XP (`/catalogs`) y Auditoría (`/audit`, con
> exportación CSV), **Mi cuenta** (`/account`: datos de la sesión y cambio de contraseña,
> visible para todo el personal), **Mentorías** (`/mentoring/assignments`,
> `/mentoring/availability` y `/mentoring/sessions`) y login/registro. Diez features (`auth`, `users`, `audit`,
> `alerts`, `gamification`, `ventures`, `indicators`, `mentoring`, `entrepreneurs`, `ai_assistant`), el shell en `components/layout/`
> y los componentes shadcn `button, input, label, switch, checkbox, slider, sheet, badge`.

### Cómo está armado el panel

- **Datos en el servidor.** Cada página (Server Component) lee con `features/<f>/server/queries.ts`
  vía `authedFetch` (cookie → Bearer) y valida la respuesta con zod. Las mutaciones son
  **server actions** (`server/actions.ts`) que llaman al backend y hacen `revalidatePath`.
- **Filtros y paginación en la URL** (`?q=&rol=&page=`, `?categoria=`, `?tab=`): la página se
  renderiza en el servidor y los enlaces son navegables. Solo la búsqueda de usuarios es un
  componente cliente (debounce de 350 ms que actualiza la URL).
- **Permisos.** El menú y cada página usan los permisos del usuario (`hasPermission`): sin
  permiso se muestra `NoAccess`, y los controles de edición se desactivan. El backend sigue
  siendo la autoridad (devuelve 403).
- **Composición entre features** solo por barrel: `catalogs/page.tsx` junta `ventures`
  (etapas) y `gamification` (retos, insignias); `(app)/page.tsx` junta `indicators` y `audit`.
- **Avisos** con un store de zustand (`components/layout/toast-store.ts`) y `<Toaster />`: entran con `toast-in`, salen
  con `toast-out` (el store marca `leaving` antes de quitarlos), tienen botón de cerrar y un error dura más (6 s) que
  una confirmación (3,2 s).
- **Carga**: `components/data/skeleton.tsx` (`PageSkeleton`, variantes `table`, `kpis` y `section`) da a cada
  `loading.tsx` la forma de lo que viene. El de `(app)` es la tabla; `/panel` y `/dashboard` usan `kpis` y las pestañas de
  la ficha, `section`.
- **Búsqueda sin recarga**: `SearchBar` usa `next/form` (navegación del lado del cliente; sin JavaScript sigue siendo un GET).
- **Filtros-píldora**: `FilterPills` o, si la pantalla arma sus enlaces, `filterPillClass(active)` del mismo archivo.
  No se copia la cadena de clases.
- **Interruptor del diseño:** `components/ui/toggle-switch.tsx` (44×26, área de clic de 44 px).
- **Fechas** en hora de Bolivia (`lib/format.ts`: «Hoy, 08:12», «Hace 3 días»).
- **Mentorías** (`features/mentoring`): `AssignmentsScreen` (coordinación habilita asesores y los asigna a
  emprendimientos; el rol `asesor` no ve el ítem), `AvailabilityScreen` (el asesor agrega, bloquea o
  elimina horarios; un solapamiento se rechaza con el motivo) y `SessionsScreen` (el asesor ve las suyas
  con `GET /sessions/me`, el resto la lista paginada `GET /sessions`; filtros de estado y periodo en la URL;
  acciones «Registrar sesión», «Realizada», «Recomendar» y «Compromiso» en hojas laterales). Las pantallas
  que cargan datos viven en `features/mentoring/components/screens.tsx` y las páginas de `app/` son de una
  línea. El asesor recibe en `/panel` un dashboard propio (`AdvisorDashboardView`, mismo diseño que el Resumen de
  coordinación: banda de marca con órbitas, tarjetas y listas) con sus emprendimientos asignados, sus mentorías
  (próximas, por registrar, realizadas este mes, compromisos), alertas abiertas y el semáforo de salud de sus
  emprendimientos. `/panel` compone los datos por barrel (`getAdvisorDashboardSnapshot`, `getHealth`,
  `countOpenAlerts`); el cálculo está en `features/mentoring/advisor-dashboard.ts`. El acceso «Mi panel» aparece en
  el sidebar. La lista de emprendimientos para los selectores llega por el barrel de `ventures`
  (`listVentureOptions`). Horas en Bolivia (UTC−4 fijo, `lib/format.ts: toBoIso`).
- **Seguimiento** (fase 3): `features/ventures` (`VenturesScreen`: lista y «Avanzar etapa», que solo ofrece
  la siguiente etapa), `features/alerts` (`AlertsScreen`: revisada/atendida/descartada, quién la atendió; el
  plazo de compromisos está en Parámetros), `features/indicators` (`DashboardScreen` y `ReportsScreen`:
  filtros de periodo y etapa en la URL, vista previa de 50 filas y CSV por `app/(app)/reports/export/route.ts`)
  y el **historial** (`HistoryScreen` en `features/mentoring`, página `/ventures/[id]/history`, con `?orden=desc`).
  Los componentes de formulario compartidos viven en `components/forms/form-bits.tsx`.
- **Salud de emprendimientos**: `/health` (`HealthScreen` en `features/indicators`, grupo «Programa» del menú,
  `seguimiento:consulta` y no ser emprendedor) lista `GET /indicators/health` del más urgente al que mejor va, con
  semáforo (texto + color, `health-level.tsx`), barra de puntaje y los motivos. El Resumen (`/panel`) muestra
  `HealthAttentionCard` con los rojos y ámbar.
- **Preguntas sin respuesta**: en `/knowledge`, `KnowledgeGapsSection` (`features/ai_assistant`) muestra
  `GET /ai/knowledge/gaps` (90 días, anónimas) para saber qué documentos faltan en la base del coach.
- **Emprendedores y emprendimientos** (fase 4): `features/entrepreneurs` (`EntrepreneursScreen`, `/entrepreneurs`:
  lista con búsqueda por nombre, correo o documento; «Nuevo emprendedor» —solo con `emprendedores:registro`— crea
  usuario y perfil juntos y muestra la clave temporal una vez). `features/ventures` suma «Nuevo emprendimiento»
  (se arma el **equipo**: uno o más emprendedores con rol, `team-picker.tsx`; lista de `listEntrepreneurOptions` por el
  barrel de `entrepreneurs`), la columna y el botón **Equipo** (`team-sheet.tsx`: ver, agregar y quitar integrantes;
  nunca deja el emprendimiento vacío), «Editar»
  (nombre, sector, descripción y estado, solo `emprendedores:modificacion`) y los enlaces «Progreso» e «Historial».
  El **progreso** (`JourneyScreen` en `features/gamification`, `/ventures/[id]/progress`) muestra XP, nivel, etapas
  completadas/actual/pendientes, la barra hacia el siguiente nivel, las insignias del equipo, el historial de XP y los retos
  del emprendimiento; es de solo lectura.
- **Base de conocimiento** (fase 5): `features/ai_assistant` (`KnowledgeScreen`, `/knowledge`, permiso `config:consulta`;
  subir y desactivar con `config:modificacion`, es decir coordinación y administración). Muestra si Ollama responde,
  los documentos activos y la tabla con el **estado de procesamiento** (Procesando, Activo, Error, Inactivo) y los
  fragmentos de cada uno. «Subir documento» acepta .txt, .md, .pdf y .docx de hasta 10 MB y llama a
  `POST /ai/knowledge/upload` desde una server action con `FormData` (`lib/api-client.ts` admite `FormData` y un plazo
  mayor, 120 s, porque calcular embeddings tarda; `next.config.ts` sube el límite de las server actions a 11 MB). Si el
  servicio de IA no responde, el intento queda visible en estado «Error».
- **Recuperación de contraseña** (CU01, `features/auth`): «¿Olvidaste tu contraseña?» en el login → `/forgot-password`
  (`forgotPasswordAction`, pide el código al backend) → `/reset-password` (`resetPasswordAction`: correo, código de
  6 dígitos y contraseña nueva) → `/login?restablecida=1`. Ambas rutas son públicas (`proxy.ts`). El backend responde
  igual exista o no el correo, así que la pantalla nunca revela cuentas; un código malo o vencido se muestra en el campo
  del código. React limpia el formulario tras cada envío: los valores que deben conservarse viajan en `state.values`.
- **Reportes** (CU21): «Exportar Excel» y «Exportar CSV» usan el mismo *route handler* (`/reports/export?formato=xlsx|csv`).
- **Pruebas** (fase 7): `pnpm test` (Vitest: esquemas y utilidades, archivos `*.test.ts` junto al código) y
  `pnpm test:e2e` (Playwright, `e2e/`). Las E2E necesitan el backend arriba **con los datos de demostración**
  (`uv run python -m emprendeu.db.seed`) y `API_URL` apuntándole; levantan la web en el puerto 3100. Usan el Chromium
  completo (`channel: "chromium"`): `npx playwright install chromium`. El backend limita la recuperación a 3 solicitudes por
  correo cada 15 min, por eso la prueba usa un correo distinto en cada ejecución. `e2e/landing.spec.ts` (portada,
  postulación, menú móvil, movimiento reducido, metadatos) no necesita el backend.
- **Cambio de contraseña** (`features/auth`: `changePasswordAction`, `ChangePasswordForm`,
  `AccountView`): el backend invalida los tokens anteriores y devuelve uno nuevo, que la acción
  guarda en la cookie para que la sesión actual siga; las demás sesiones se cierran. «Contraseña
  actual incorrecta» llega como 400 `wrong_password` y se marca en el campo (no es un 401).
- Cambiar el rol de un usuario existente (`PATCH /users/{id}/rol`) está en la tabla de
  usuarios: es lo que permite que una cuenta registrada desde la web llegue a usar el panel.
- **Landing pública** (`/`, `app/(public)/page.tsx` → `features/landing`): presenta el programa a
  estudiantes y lleva a `/apply`. «Personal CIE-U» va a `/login` (o «Ir al panel» si hay sesión); es
  discreto porque el panel rechaza a los emprendedores. Diseño y orden de secciones en `design.md`
  («Landing pública»). Piezas:
  - `components/primitives.tsx`: `LandingButton` (accent/primary/ghost), `Container`, `SectionHeading`,
    `SectionLead` y `delay()`. No se repiten clases de botón ni de título a mano.
  - `content.ts`: **todo** el texto visible, las etiquetas de acción (`CTA`) y `APP_DOWNLOAD_URL`.
  - Animaciones con **anime.js 4** dentro de `useAnimeScope` (`hooks/use-anime-scope.ts`: `createScope` con
    media query de movimiento reducido, revierte al desmontar, y por defecto **se prepara solo al acercarse**
    la sección; el hero y la escena fijada pasan `lazy: false`). Las piezas se seleccionan con
    `data-part` y el helper `part()`, nunca por clases de Tailwind. El CSS solo oculta `[data-reveal]`
    mientras la sección vale `data-anim="pending"`.
  - El **h1 del hero entra con CSS** (`.landing-rise`/`.landing-pop` en `globals.css`), no con JS.
  - **«Pausar animaciones»**: `stores/motion-store.ts` (zustand) + `components/motion-toggle.tsx`. Los bucles
    de anime.js se registran con `ambient([...])`; los temporizadores consultan `motionPaused()`; los
    bucles CSS llevan `.landing-ambient` (`html[data-motion="paused"]`).
  - Cabecera, pie, «Lo esencial», «Personas», «Preguntas» (`<details>`) y el cierre son **Server
    Components**; la cabecera usa animaciones CSS ligadas al scroll.
  - Metadatos Open Graph en la página; la URL absoluta sale de `SITE_URL` (`lib/env.ts`). La imagen
    para compartir es `app/opengraph-image.tsx` (1200 × 630, generada), el icono `app/icon.png`, y hay
    `app/robots.ts` y `app/sitemap.ts` (solo `/` y `/apply` son indexables). `Faq` emite los datos
    estructurados `FAQPage` desde el mismo `FAQ` de `content.ts`.
  - **Menú móvil** (`components/mobile-menu.tsx`, cliente): bajo `lg` reemplaza los enlaces de la
    cabecera; se cierra al elegir o con Escape. «Pausar animaciones» muestra solo el icono bajo `sm`.
  - La portada **no depende del backend**: si `getSession()` falla, se muestra como sin sesión.
  `proxy.ts` deja públicas la ruta exacta `/` y sus metadatos (`/opengraph-image`, `/icon.png`,
  `/robots.txt`, `/sitemap.xml`).
- **Postulación** (`/apply`, `ApplyView` en `features/entrepreneurs`): pantalla dividida con el
  `BrandPanel` de `auth` (variante `compact`, con su propio mensaje) y los pasos `APPLY_STEPS` que
  exporta el barrel de `landing`; enlace «Volver al inicio» y, al enviar, qué pasa después.
- **Asistente de ayuda** (`features/ai_assistant`: `HelpChat`, `stores/help-chat-store.ts`, `askHelpAction`): botón
  flotante abajo a la derecha en todo el área autenticada (lo compone `app/(app)/layout.tsx` y `AppShell` lo pinta
  en su ranura `overlays`). Chat con `POST /ai/help` (Gemini o, sin cupo, la guía sin IA, marcada como tal),
  preguntas sugeridas según la ruta (`help-suggestions.ts`), Markdown mínimo sin HTML, `Esc` cierra. La conversación
  vive solo en el store (se conserva al navegar, se pierde al recargar). Los avisos (`Toaster`) suben a `bottom-24`
  para no tapar el botón.
- **Tutorial guiado** (`features/auth/components/tour/`: `GuidedTour`, `RestartTourButton`, `tour-steps.ts`; store
  `features/auth/stores/tour-store.ts`): si `/auth/me` trae `tutorial_completado_at = null`, arranca solo al entrar.
  Oscurece la pantalla, recorta el elemento del paso (`data-tour="nav"`, `nav-group-<grupo>`, `account`, `help`) y
  explica cada grupo del menú **ya filtrado por permisos** (los pasos los arma el layout en el servidor). Sin elemento
  visible (menú cerrado en el celular) el globo va centrado. Teclado: `←`/`→`, `Esc` salta. Terminar o saltar llama a
  `completeTutorialAction` (`POST /auth/me/tutorial`). «Ver el tutorial del sistema» (pie del chat y «Mi cuenta») lo repite.
  Al agregar una pantalla al `NAV`, añade su texto en `SCREEN_TEXT` de `tour-steps.ts` y en `help_guide.py` del backend.
- **Páginas de estado**: `app/not-found.tsx` y `app/error.tsx` usan `components/layout/status-screen.tsx`;
  dentro del panel, `app/(app)/error.tsx` (el menú sigue en pantalla) y `app/(app)/loading.tsx`. En
  Next 16 el error recibe `retry` (no `reset`).
- **IP del visitante**: `lib/api-client.ts` reenvía en `X-Forwarded-For` la IP de quien visita (la
  última de la cabecera entrante), para que los límites por IP del backend cuenten por persona y no
  por el servidor de la web. El backend solo la cree si la web está en su `TRUSTED_PROXIES`.
- **Cabeceras de seguridad** en `next.config.ts` (`X-Frame-Options`, `nosniff`, `Referrer-Policy`,
  `Permissions-Policy` y HSTS en producción).
- **El Resumen del panel está en `/panel`** (antes `/`): login y registro redirigen ahí.
- **Menú agrupado** (`app/(app)/layout.tsx` → `NAV`): Inicio, Programa, Acompañamiento y
  Configuración; cada ítem declara su permiso y los grupos vacíos no se muestran. «Mi cuenta» es la
  tarjeta del usuario al pie. En `< lg` el menú es una hoja izquierda (`components/layout/mobile-nav.tsx`).
- **Ficha del emprendimiento** (`app/(app)/ventures/[id]/layout.tsx` → `VentureHeader` de `ventures`):
  datos, acciones (Equipo, Editar, Pasar a…), trayecto de etapas animado (`StageTrack`) y pestañas
  (`TabNav`: Progreso, Seguimiento, Etapas —con `seguimiento:consulta`—, Documentos, Historial). Las
  pantallas de cada pestaña pintan un `SectionHeader` (h2), no un `PageHeader`. `/ventures/{id}` redirige a
  la primera pestaña visible. Las acciones de `ventures` revalidan también `/ventures/[id]` (layout).
- **Transición entre páginas**: `components/layout/page-transition.tsx` envuelve el contenido en el
  `<ViewTransition>` de React con la ruta como `key` (clase `.page` en `globals.css`).
- **Radios, sombras y movimiento** salen de `globals.css`: `rounded-xl` = 12 px (botón, input), `rounded-2xl` = 16 px
  (tarjeta); sombras `shadow-raised`, `shadow-overlay`, `shadow-cta`, `shadow-knob`; curvas `ease-enter`, `ease-exit`,
  `ease-spring`. `Button` tiene tres alturas: `default` (36), `lg` (44) y `xl` (52).
- **Tokens**: no hay hex en crudo en `features/` ni `components/` (`grep -rnE '\[#[0-9a-fA-F]{3,6}\]'`
  debe salir vacío). Los pares de estado son `danger-*`, `warning-*`, `success*`, `info-foreground`.

### Autenticación (cómo funciona hoy)

- **Sesión = cookie `emprendeu_session`** (`httpOnly`, `sameSite=lax`, `secure` en
  producción) con el JWT del backend. El navegador nunca ve el token ni llama al
  backend: todo pasa por **server actions** (`features/auth/server/actions.ts`) y
  Server Components, vía `lib/api-client.ts` (`server-only`).
- **Variable de entorno:** `API_URL` (por defecto `http://localhost:8000/api/v1`).
  Plantilla en `.env.example`; local en `.env.local`. No hace falta CORS.
- **Dos barreras:** `proxy.ts` (sin cookie → `/login`) y `requireSession()` en el layout
  de `(app)`, que valida el token con `GET /auth/me`. `/login` y `/register` redirigen a
  `/` si ya hay sesión.
- **El panel es solo para personal.** Una cuenta con rol `emprendedor` se rechaza en el
  login («usa la app móvil»). El registro público siempre crea un **emprendedor**, así
  que la cuenta nueva no entra al panel hasta que un administrador le cambie el rol
  (`PATCH /users/{id}/rol`).
- Los formularios usan `useActionState`; los errores del contrato (`error.code`) se
  traducen a mensajes en `actions.ts`. Las respuestas del backend se validan con zod
  (`features/auth/schemas/api-schemas.ts`).

## 2. Qué significa "feature-based" aquí

`app/` es **únicamente enrutado**. Todo el código de producto vive en
`features/<feature>/`, cada una autocontenida (UI, estado, datos, tipos) y con una
API pública explícita. Una feature se puede leer, mover o borrar entera sin
rastrear piezas por media docena de carpetas técnicas.

## 3. Estructura de carpetas

```
app/                          # SOLO routing: layout / page / loading / error / route.ts
├── (public)/                 # route group: landing, login, registro
├── (app)/                    # route group: área autenticada (layout propio)
│   └── projects/page.tsx     # página delgada: compone desde features/projects
├── api/                      # route handlers (BFF) — sin reglas de negocio
├── layout.tsx
└── globals.css               # tokens de Tailwind v4 y tema
features/
└── <feature>/
    ├── components/           # UI propia de la feature
    ├── hooks/                # hooks de cliente
    ├── server/               # 'server-only': data access + server actions ('use server')
    ├── stores/               # stores de zustand de la feature
    ├── schemas/              # validación (zod) y tipos derivados
    ├── types.ts
    └── index.ts              # API PÚBLICA: único import permitido desde fuera
components/
├── ui/                       # primitivas shadcn — generadas, sin lógica de negocio
├── layout/                   # shell, sidebar agrupado, menú móvil, PageHeader, SectionHeader, transición de página
├── forms/                    # piezas de formulario en hojas laterales (form-bits)
└── data/                     # presentación de datos sin negocio: DataTable, SearchBar, FilterPills,
                              # StatusPill, EmptyState, TabNav, CountUp, Skeleton/PageSkeleton
lib/                          # api-client ✅, env ✅, constants, utils (sin negocio)
hooks/                        # hooks genéricos reutilizables
proxy.ts                   ✅ # (Next 16) antiguo middleware: protege rutas privadas
```

### Features previstas (mapa inicial — ajústalo con el usuario antes de implementar)

`auth` ✅, `users` ✅, `audit` ✅, `alerts` ✅, `gamification` ✅, `ventures` ✅, `indicators` ✅, `mentoring` ✅, `entrepreneurs` ✅, `ai_assistant` ✅ (todas conectadas al backend); `training` ✅ (`/training`, `/training/[id]`), `landing` ✅ (`/`, página pública; no es un módulo del backend), `documents` ✅ (`/ventures/[id]/documents`, con descarga por `route.ts`) — los
mismos nombres que los módulos del backend (regla global §4.6). Registra aquí cada feature nueva.

## 4. Reglas de la web

1. **`app/` no contiene lógica.** Un `page.tsx` importa de `@/features/<f>` y
   compone. Si un archivo de `app/` pasa de ~50 líneas, su contenido pertenece a
   una feature.
2. **Imports entre features solo por el barrel**: `@/features/projects`, nunca
   `@/features/projects/components/ProjectCard`. Lo que dos features comparten
   sube a `components/`, `lib/` o `hooks/`.
3. **Las features no importan de `app/`.** Nunca.
4. **`components/ui/` es intocable por el negocio**: son primitivas generadas por
   shadcn (`pnpm dlx shadcn@latest add <comp>`). No metas llamadas a datos ni
   reglas ahí; si necesitas una variante, compónla en `features/<f>/components/`.
5. **Frontera servidor/cliente explícita.** Server Component por defecto.
   `'use client'` solo en la hoja del árbol que realmente necesita interactividad,
   nunca en un layout o página completa "por comodidad". Los archivos de
   `features/<f>/server/` llevan `import 'server-only'`. Las funciones o constantes que
   usan a la vez Server y Client Components (etiquetas, formateadores, como
   `features/users/roles.ts` o `features/ventures/roles.ts`) van en un módulo **sin**
   `'use client'`: un Server Component no puede llamar a una función exportada desde un
   archivo de cliente (da `Attempted to call X() from the server`).
6. **Acceso a datos**: desde Server Components y server actions en
   `features/<f>/server/`, usando el cliente de `lib/api-client.ts`. Un componente
   cliente no hace `fetch` directo al backend; recibe props o llama a una server action.
7. **Zustand solo para estado de UI de cliente** (filtros, modales, wizard), uno
   por feature en `features/<f>/stores/`. Lo que es estado del servidor no va a un
   store: se obtiene en el servidor o se cachea con las herramientas de Next.
8. **Validación en el borde**: toda entrada de usuario y toda respuesta del backend
   se valida con el esquema de `features/<f>/schemas/` antes de entrar en la app.
9. **Tipos del dominio en la feature** (`types.ts`), derivados del contrato del
   backend. No se duplican en `lib/`.
10. **Estilos solo con utilidades de Tailwind y los tokens de `globals.css`**.
    Nada de CSS-in-JS ni de colores en crudo fuera de los tokens.
11. **Antes de escribir código de Next, lee la guía correspondiente en
    `node_modules/next/dist/docs/`** (lo exige el bloque gestionado de arriba):
    esta versión difiere de lo que el modelo "recuerda".
12. **`pnpm lint` y `pnpm build` deben pasar** antes de dar un cambio por terminado.
