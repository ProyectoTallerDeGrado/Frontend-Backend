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

Sin librería de datos ni de formularios todavía. Cuando hagan falta:
`zod` (validación) y, si el estado de servidor lo justifica,
`@tanstack/react-query` **solo** para datos consumidos desde componentes cliente.

> Estado real hoy: solo la plantilla de `create-next-app`
> (`app/layout.tsx`, `app/page.tsx`, `components/ui/button.tsx`, `lib/utils.ts`).

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
lib/                          # api-client, env, constants, utils (sin negocio)
hooks/                        # hooks genéricos reutilizables
proxy.ts                      # (Next 16) antiguo middleware, si hace falta
```

### Features previstas (mapa inicial — ajústalo con el usuario antes de implementar)

`auth`, `users`, `projects`, `mentoring`, `events` — los mismos nombres que los
módulos del backend (regla global §4.6). Registra aquí cada feature nueva.

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
