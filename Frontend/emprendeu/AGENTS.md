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

`zod` (validación de `features/auth`) y `server-only` ya están instalados. Sin librería de datos ni de formularios todavía.
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
- **Avisos** con un store de zustand (`components/layout/toast-store.ts`) y `<Toaster />`.
- **Interruptor del diseño:** `components/ui/toggle-switch.tsx` (44×26, área de clic de 44 px).
- **Fechas** en hora de Bolivia (`lib/format.ts`: «Hoy, 08:12», «Hace 3 días»).
- **Mentorías** (`features/mentoring`): `AssignmentsScreen` (coordinación habilita asesores y los asigna a
  emprendimientos; el rol `asesor` no ve el ítem), `AvailabilityScreen` (el asesor agrega, bloquea o
  elimina horarios; un solapamiento se rechaza con el motivo) y `SessionsScreen` (el asesor ve las suyas
  con `GET /sessions/me`, el resto la lista paginada `GET /sessions`; filtros de estado y periodo en la URL;
  acciones «Registrar sesión», «Realizada», «Recomendar» y «Compromiso» en hojas laterales). Las pantallas
  que cargan datos viven en `features/mentoring/components/screens.tsx` y las páginas de `app/` son de una
  línea. La lista de emprendimientos para los selectores llega por el barrel de `ventures`
  (`listVentureOptions`). Horas en Bolivia (UTC−4 fijo, `lib/format.ts: toBoIso`).
- **Seguimiento** (fase 3): `features/ventures` (`VenturesScreen`: lista y «Avanzar etapa», que solo ofrece
  la siguiente etapa), `features/alerts` (`AlertsScreen`: revisada/atendida/descartada, quién la atendió; el
  plazo de compromisos está en Parámetros), `features/indicators` (`DashboardScreen` y `ReportsScreen`:
  filtros de periodo y etapa en la URL, vista previa de 50 filas y CSV por `app/(app)/reports/export/route.ts`)
  y el **historial** (`HistoryScreen` en `features/mentoring`, página `/ventures/[id]/history`, con `?orden=desc`).
  Los componentes de formulario compartidos viven en `components/forms/form-bits.tsx`.
- **Emprendedores y emprendimientos** (fase 4): `features/entrepreneurs` (`EntrepreneursScreen`, `/entrepreneurs`:
  lista con búsqueda por nombre, correo o documento; «Nuevo emprendedor» —solo con `emprendedores:registro`— crea
  usuario y perfil juntos y muestra la clave temporal una vez). `features/ventures` suma «Nuevo emprendimiento»
  (se elige el emprendedor; lista de `listEntrepreneurOptions` por el barrel de `entrepreneurs`), «Editar»
  (nombre, sector, descripción y estado, solo `emprendedores:modificacion`) y los enlaces «Progreso» e «Historial».
  El **progreso** (`JourneyScreen` en `features/gamification`, `/ventures/[id]/progress`) muestra XP, nivel, etapas
  completadas/actual/pendientes y los retos del emprendimiento; es de solo lectura.
- **Base de conocimiento** (fase 5): `features/ai_assistant` (`KnowledgeScreen`, `/knowledge`, permiso `config:consulta`;
  subir y desactivar con `config:modificacion`, es decir coordinación y administración). Muestra si Ollama responde,
  los documentos activos y la tabla con el **estado de procesamiento** (Procesando, Activo, Error, Inactivo) y los
  fragmentos de cada uno. «Subir documento» acepta .txt, .md, .pdf y .docx de hasta 10 MB y llama a
  `POST /ai/knowledge/upload` desde una server action con `FormData` (`lib/api-client.ts` admite `FormData` y un plazo
  mayor, 120 s, porque calcular embeddings tarda; `next.config.ts` sube el límite de las server actions a 11 MB). Si el
  servicio de IA no responde, el intento queda visible en estado «Error».
- **Cambio de contraseña** (`features/auth`: `changePasswordAction`, `ChangePasswordForm`,
  `AccountView`): el backend invalida los tokens anteriores y devuelve uno nuevo, que la acción
  guarda en la cookie para que la sesión actual siga; las demás sesiones se cierran. «Contraseña
  actual incorrecta» llega como 400 `wrong_password` y se marca en el campo (no es un 401).
- Cambiar el rol de un usuario existente (`PATCH /users/{id}/rol`) está en la tabla de
  usuarios: es lo que permite que una cuenta registrada desde la web llegue a usar el panel.

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
└── layout/                   # header, sidebar, shells compartidos
lib/                          # api-client ✅, env ✅, constants, utils (sin negocio)
hooks/                        # hooks genéricos reutilizables
proxy.ts                   ✅ # (Next 16) antiguo middleware: protege rutas privadas
```

### Features previstas (mapa inicial — ajústalo con el usuario antes de implementar)

`auth` ✅, `users` ✅, `audit` ✅, `alerts` ✅, `gamification` ✅, `ventures` ✅, `indicators` ✅, `mentoring` ✅, `entrepreneurs` ✅, `ai_assistant` ✅ (todas conectadas al backend); pendientes `training`, `documents` — los
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
   `features/<f>/server/` llevan `import 'server-only'`.
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
