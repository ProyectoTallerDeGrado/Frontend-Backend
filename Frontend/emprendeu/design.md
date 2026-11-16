# Web EmprendeU (CIE-U) — Diseño del Panel de Administración

> Fuente: mockup «CIE-U · Mockups Administrador Web y App Móvil» (artboards `Web · Ingreso` y
> `Web · Panel de administración`, lienzo 1440 px).
> Lee antes `AGENTS.md` (arquitectura feature-based) y `../../AGENTS.md` (reglas globales).
> Este documento describe **cómo se ve y se comporta** la web; el `AGENTS.md` dice **dónde va el código**.
> Es prescriptivo: nada de esto está implementado todavía (hoy solo existe la plantilla de `create-next-app`).

---

## 0. Reorganización del panel (2026-11-14) — prevalece sobre lo que contradiga abajo

El panel creció a 19 secciones; esta revisión lo ordena sin cambiar la marca.

- **Menú agrupado por tarea**: *Inicio* (Resumen, Indicadores, Reportes) · *Programa* (Admisiones,
  Emprendedores, Emprendimientos, Necesidades, Alertas) · *Acompañamiento* (Asignaciones, Mi
  disponibilidad, Sesiones, Capacitaciones) · *Configuración* (Usuarios, Roles y permisos, Parámetros,
  Catálogos y XP, Base de conocimiento, Auditoría). Los grupos se pliegan; el del ítem activo no.
  «Mi cuenta» es la tarjeta del usuario al pie. Sidebar fijo (`sticky`, 272 px) con scroll propio.
- **Móvil (< 1024 px)**: barra superior navy de 64 px con el logo y un botón que abre el mismo menú en
  una hoja izquierda; se cierra al navegar. Enlace «Saltar al contenido».
- **Ficha del emprendimiento** (`/ventures/[id]/*`): una sola cabecera (volver a Emprendimientos, nombre,
  estado, sector, integrantes, acciones), el **trayecto de etapas** y pestañas Progreso · Seguimiento ·
  Etapas · Documentos · Historial. La lista de emprendimientos ya no lleva cinco enlaces por fila: el
  nombre abre la ficha.
- **Componentes comunes** (`components/data/`): tabla, buscador, filtros-píldora, píldora de estado,
  estado vacío, pestañas y cifra animada. Las cabeceras de tabla dejan las MAYÚSCULAS.
- **Movimiento** (todo cae con `prefers-reduced-motion`). Lo llamativo está concentrado en dos sitios
  con el motivo de órbitas de la marca:
  - *Resumen*: franja navy con las órbitas girando; **cada satélite es un emprendimiento activo**
    (hasta 18) y la cifra cuenta hacia arriba al cargar.
  - *Trayecto de etapas*: la línea crece hasta la etapa actual, los nodos aparecen en secuencia
    (`node-pop`) y la etapa actual tiene un halo que late.
  - El resto responde a la persona: el resaltado del menú y el subrayado de las pestañas **se deslizan**
    al ítem nuevo, los grupos del menú se pliegan con transición, las páginas se cambian con un fundido
    corto (View Transitions de React), la barra «cambios sin guardar» sube desde abajo. Se quitó el
    `fadeUp` escalonado de filas y tarjetas y la sombra al pasar sobre tarjetas estáticas.
- **Tokens nuevos** en `globals.css`: `surface-head`, `row-hover`, `danger-tint/-foreground`,
  `warning-tint/-foreground/-soft/-border`, `success`, `success-bright`, `gold`, `switch-off`,
  `on-navy-dim`, `primary-hover`, `on-accent`, `info-foreground`. No queda hex en crudo en el código.
- El login dice «Panel del personal del CIE-U» (ya no es solo para el administrador).

### Landing pública (`/`) — revisada el 2026-11-15

Para estudiantes que emprenden; el Resumen del panel pasó a `/panel`. Concepto **«Tu idea, en órbita»**:
el núcleo es la idea y lo que gira alrededor es lo que da el CIE-U. Animaciones con anime.js 4.

**Ajustes del 2026-11-15.** Ningún satélite va en el anillo interior (la etiqueta tapaba «Tu idea»);
bajo `lg` hay menú de secciones en la cabecera; «Pausar animaciones» es solo icono bajo `sm`. La
postulación (`/apply`) continúa la portada: panel azul de marca con los tres pasos a la izquierda
(en pantallas chicas, panel corto y sin órbita) y el formulario a la derecha, con «Volver al inicio».
Las páginas 404 y de error usan el mismo fondo azul con órbita. Imagen para compartir: titular sobre
azul, 1200 × 630.

**Principio: un solo momento grande.** La escena Problema → Giro es el único efecto protagonista; el
resto se mueve poco y siempre con un propósito. Nada de marquesinas, botones magnéticos ni parallax.

Orden de la página:

1. **Hero** (navy, alto de pantalla). El titular (Sora, hasta 96 px), el texto y los botones entran con
   **CSS** (`.landing-rise`, `.landing-pop`), no con JS: el h1 es el LCP y está visible desde el HTML. La
   palabra resaltada rota (idea → app → tienda…) cada 3,2 s y se detiene al pasar el cursor. La órbita
   (anillos que se dibujan, núcleo «Tu idea», satélites con lo que da el CIE-U) gira muy lento. Botones
   «Postula tu emprendimiento» (`accent`) y «Ver cómo funciona» (`ghost`). Debajo, para el estudiante que ya
   está dentro: «¿Ya estás en el programa? Entra desde la app» (enlace si `APP_DOWNLOAD_URL` existe).
2. **El problema y el giro** (escena fijada de 220vh, solo escritorio con movimiento): caen las notas, la
   idea se apaga, el fondo pasa a azul y cada nota se voltea con la respuesta. En móvil, lista de pares.
3. **El camino**: las cuatro etapas (numeradas porque son una secuencia). Ruta SVG con cometa al ritmo del
   scroll; el texto nunca baja de 0,6 de opacidad.
4. **La app**: teléfono fijo con 4 pantallas (Inicio, Camino, Mentorías, Coach IA).
5. **Y detrás de la app, personas** (`blue-50`): lo que hacen asesores y coordinación.
6. **Lo esencial** (`#esencial`): lista de definiciones con filete superior (no tarjetas). Solo datos
   confirmados; fechas de convocatoria y contacto se agregan cuando el CIE-U los dé.
7. **Cómo postular**: tres pasos unidos por una línea.
8. **Preguntas** (`#preguntas`): `<details name="faq">` nativo, una abierta a la vez.
9. **Cierre** navy con órbita en CSS y el mismo botón. **Pie** con las anclas, «Postular» y «Personal CIE-U».

**Cabecera**: transparente sobre el hero y navy al bajar, con barra de progreso de lectura; ambas son
animaciones CSS ligadas al scroll (`animation-timeline: scroll()`). Sin soporte o con «reducir
movimiento», queda siempre sólida. «Personal CIE-U» es discreto y en móvil se va al pie: la web es del
personal; el estudiante usa la app.

**Textos**: todos en `features/landing/content.ts`. Cada acción se nombra igual en toda la página
(`CTA`: «Postula tu emprendimiento», «Postular» en la cabecera).

**Movimiento y accesibilidad**:
- Botón fijo **«Pausar animaciones»** (abajo a la izquierda, WCAG 2.2.2): detiene la órbita, la palabra
  rotatoria, el recorrido del teléfono en móvil y los bucles CSS (`.landing-ambient`). Se recuerda en el
  navegador. Lo ligado al scroll no se pausa: lo controla quien lee.
- «Reducir movimiento»: no se anima nada y todo queda visible; sin JavaScript también (`<noscript>`).
- Enlace «Saltar al contenido» al tabular.

**Forma**: radios por jerarquía (`rounded-lg` en íconos y chips cuadrados, `rounded-xl` en botones y
tarjetas, grande solo en el teléfono). Sombras con nombre (`shadow-float`, `shadow-note`, `shadow-card-deep`,
`shadow-phone`, `shadow-glow-*`). Resplandores con `.landing-glow` (gradiente radial), sin `filter: blur`.

## 1. Alcance

La web es **solo para el rol Administrador del sistema** (Centro de Innovación y Emprendimiento
Universitario, FCEE · UAGRM, Santa Cruz, Bolivia). Los emprendedores usan la app móvil.

Pantallas del mockup:

| # | Pantalla | Ruta propuesta | Descripción |
|---|---|---|---|
| 1 | Ingreso administrador | `/login` | Panel de marca + formulario |
| 2 | Resumen | `/` | KPIs, usuarios por rol, estado de servicios, actividad reciente |
| 3 | Usuarios | `/users` | Tabla con búsqueda, filtros por rol, alta en drawer, habilitar/deshabilitar |
| 4 | Roles y permisos | `/roles` | Matriz módulo × acción por rol |
| 5 | Parámetros de seguimiento | `/settings/tracking` | Inactividad, sentimiento, alertas |
| 6 | Catálogos y XP | `/catalogs` | Pestañas Etapas / Retos / Insignias |
| 7 | Auditoría | `/audit` | Registro de acciones sensibles + exportar CSV |

En el mockup las seis vistas internas son una sola página con estado (`view`); en la web real cada
una es una **ruta** del App Router dentro del route group `(app)`.

---

## 2. Principios visuales

- **Institucional y sobrio**: azul marino profundo + azul de acción; el rojo se usa solo como acento
  (punto de estado, CTA destructivo/de confirmación, insignias) y nunca como color dominante.
- **Claridad administrativa**: tablas densas pero legibles, píldoras de estado, interruptores grandes.
- **Accesibilidad como requisito**: objetivos táctiles/clic ≥ 44 px, contraste ≥ 4.5:1, foco visible
  con anillo de 3 px, `prefers-reduced-motion` respetado, semántica real (`button`, `label`, `role="switch"`).
- **Movimiento con propósito**: entradas `fadeUp` escalonadas, barras que crecen, toasts, drawer.
  Todo se desactiva con `prefers-reduced-motion: reduce`.
- Idioma de la UI: **español**. Código e identificadores: inglés (regla global §4.9).

---

## 3. Tokens de diseño

Se declaran como variables CSS en `app/globals.css` (Tailwind v4, sin `tailwind.config`) y se
exponen en `@theme inline`. **Prohibido** usar hex en crudo fuera de los tokens (regla web §4.10).

### 3.1 Color

**Marca / azules**

| Token propuesto | Hex | Uso |
|---|---|---|
| `navy-950` | `#021F50` | Panel de marca del login, sidebar, scrim de overlays (`rgba(2,31,80,.55)`) |
| `navy-900` | `#0A1A44` | Tarjetas oscuras, avatar de rol Administrador, filtros/pestañas activas oscuras |
| `blue-600` (**primary**) | `#1F4FD6` | Botones primarios, enlaces, switches activos, foco, sliders |
| `blue-700` | `#123AA8` | Hover de enlaces |
| `blue-800` | `#12308A` | Texto sobre azul claro (chips, banner de sincronización) |
| `blue-900` | `#0F2F8C` | Texto de píldora «Coordinador» |
| `blue-100` | `#DCE6FF` | Píldora Coordinador, flash de fila nueva |
| `blue-50` | `#EAF0FF` | Hover ghost, tarjeta de rol seleccionada, aviso informativo |
| `blue-300` | `#9FB4EE` / `#B4C4EE` / `#C9D6F5` / `#E3EAFB` | Texto secundario sobre fondo oscuro (de menor a mayor claridad) |

**Acento (rojo)**

| Token | Hex | Uso |
|---|---|---|
| `red-600` | `#D61F3A` | Órbita decorativa, barra «Asesor», insignia «Validador» |
| `red-400` | `#FF5468` | Punto de nav activo, punto del chip de rol, botón «Confirmar y aplicar» |
| `red-100` | `#FFE3E8` | Fondo de píldora Asesor, chip de XP, estado «Rechazado» |
| `red-800` | `#8F0F25` | Texto sobre `red-100`, KPI «deshabilitadas» |
| `error` | `#B3122D` | Borde y mensaje de error de campo |

**Estados**

| Token | Hex | Uso |
|---|---|---|
| `green-700` | `#0E7A4F` | Operativo, cuenta habilitada, barra «Emprendedor» |
| `green-800` | `#0A5C39` | Texto sobre verde claro |
| `green-100` | `#DDF3E7` | Píldoras «Operativo», «Habilitada», «Exitoso» |
| `green-300` | `#7FE0B0` | Check sobre fondo oscuro |
| `amber-100` / `amber-50` | `#FFF0CC` / `#FFF6DC` | Avatar, barra «cambios sin guardar» |
| `amber-900` | `#6B4700` | Texto sobre ámbar |
| `amber-border` | `#F0DDA0` | Borde superior de la barra de cambios |
| `purple-600` | `#7A3FD1` | Insignia «Conector» |
| `gold-700` | `#B26A00` | Insignia «Graduado» |
| (avatar) | `#E8E2FF` / `#3C2A9B` | Quinto par de avatares |

**Neutros**

| Token | Hex | Uso |
|---|---|---|
| `ink` (foreground) | `#0E1730` | Texto principal |
| `ink-2` | `#2B3552` | Texto secundario fuerte |
| `muted-foreground` | `#4A5675` | Texto de apoyo, etiquetas |
| `border-strong` (input) | `#CBD3E6` | Bordes de inputs, botones ghost |
| `border` | `#E1E6F0` | Bordes de tarjetas |
| `border-soft` | `#EEF2FA` | Separadores de filas |
| `surface-muted` | `#F4F6FB` | **Fondo de página**, botones icono |
| `surface-head` | `#F8FAFE` | Cabecera de tablas |
| `row-hover` | `#F4F7FF` | Hover de fila |
| `switch-off` | `#9AA6C4` | Pista de switch apagado, borde de checkbox sin marcar |
| `card` | `#FFFFFF` | Tarjetas |

> Mapeo a shadcn: `--primary` = `blue-600`, `--background` = `surface-muted`, `--card` = blanco,
> `--foreground` = `ink`, `--muted-foreground`, `--border`, `--input` = `border-strong`,
> `--ring` = `blue-600`, `--destructive` = `error`, `--sidebar` = `navy-950`,
> `--sidebar-foreground` = `#C9D6F5`, `--sidebar-accent` = `rgba(255,255,255,.14)`.
> Mantener también `--chart-1..5` con `navy-900, blue-600, red-600, green-700, gold-700`.
> Modo oscuro: **no diseñado** en el mockup; no implementarlo sin pedirlo.

**Colores por rol** (se repiten en píldoras, barras y avatares):

| Rol (`rol`) | Etiqueta | Fondo | Texto | Color de barra |
|---|---|---|---|---|
| `admin` | Administrador | `#0A1A44` | `#FFFFFF` | `#0A1A44` |
| `coord` | Coordinador | `#DCE6FF` | `#0F2F8C` | `#1F4FD6` |
| `asesor` | Asesor / Mentor | `#FFE3E8` | `#8F0F25` | `#D61F3A` |
| `emp` | Emprendedor | `#DDF3E7` | `#0A5C39` | `#0E7A4F` |

Avatares de usuario (ciclo por `id % 5`): `#DCE6FF/#0F2F8C`, `#FFE3E8/#8F0F25`, `#DDF3E7/#0A5C39`,
`#FFF0CC/#6B4700`, `#E8E2FF/#3C2A9B`.

### 3.2 Tipografía

| Rol | Familia | Pesos |
|---|---|---|
| Títulos y cifras | **Sora** | 500, 600, 700 |
| Cuerpo y UI | **DM Sans** | 400, 500, 600, 700 |

Cargar con `next/font/google` (no `<link>`) y asignar a `--font-sans` (DM Sans) y `--font-heading`
(Sora). `font-heading` ya existe en `@theme inline`.

| Uso | Familia | Tamaño | Peso | Interlineado / tracking |
|---|---|---|---|---|
| Hero del login | Sora | 46 px | 700 | 1.1 / −0.02em, `text-wrap: balance` |
| Título de formulario (login) | Sora | 28 px | 700 | −0.01em |
| Título de página (`h1`) | Sora | 30 px | 700 | −0.02em |
| KPI | Sora | 38 px | 700 | −0.02em |
| Valor de parámetro | Sora | 34 px (principal) / 22 px (secundario) | 700 | −0.02em |
| Título de sección (`h2`) | Sora | 18 px | 600–700 | — |
| Título de drawer | Sora | 20 px | 600 | — |
| Subtítulo / descripción | DM Sans | 16 px | 400 | 1.5, `max-width` 680 px |
| Texto de fila / botón | DM Sans | 15 px | 600 | — |
| Texto de apoyo | DM Sans | 14 px | 400–600 | — |
| Notas, metadatos | DM Sans | 13 px | 400–700 | — |
| Cabecera de tabla | DM Sans | 13 px | 600, sentence case, `muted-foreground` | — (antes MAYÚSCULAS; ver §0) |
| Encabezado de grupo del menú | DM Sans | 12.5 px | 600, `on-navy-dim` | — |

### 3.3 Espaciado, radios y sombras

- Unidad base 4 px. Paddings recurrentes: 8, 12, 16, 20, 24, 28, 32, 40. Gap de rejillas: 16 / 24.
- Contenido principal: `padding: 32px 40px 64px`; cabecera de página con `margin-bottom: 28px`.
- **Radios**: píldora `999px`; tarjeta `16px`; input/botón `12px`; botón de login `12px`; logo `11–14px`;
  switch `999px`; checkbox `7px`; control +/− `10px`; drawer sin radio.
- **Sombras**: tarjeta hover `0 14px 30px -18px rgba(10,26,68,.35)`; botón primario hover
  `0 10px 22px -10px rgba(31,79,214,.75)` (login: `0 12px 24px -10px rgba(31,79,214,.7)`);
  drawer `-24px 0 60px -20px rgba(2,31,80,.5)`; toast `0 18px 40px -12px rgba(2,31,80,.6)`;
  knob de switch `0 1px 3px rgba(0,0,0,.3)`.
- **Anillo de foco de input**: `border-color: blue-600` + `box-shadow: 0 0 0 4px rgba(31,79,214,.16)`.
  Foco de teclado en botones/enlaces: `outline: 3px solid blue-600; outline-offset: 2px`.

### 3.4 Movimiento

> **Regla:** un solo momento animado por pantalla y movimiento que responde a una acción. Lo que entra
> desacelera (`ease-enter`), lo que sale dura menos (`ease-exit`) y el rebote (`ease-spring`) se reserva para
> confirmar. No se repite `fadeUp` en cada bloque: en login y postulación solo entra el titular del panel de marca.

| Animación | Detalle |
|---|---|
| `fadeUp` | `opacity 0→1`, `translateY(14–18px)→0`, .4–.7 s, escalonada por `delay` (35–120 ms por ítem) |
| `slideIn` (formulario login) | `translateX(28px)→0`, .8 s, delay .15 s |
| `growX` | barras de «Usuarios por rol»: `scaleX 0→1`, .9 s, delay 200 ms + 120 ms por barra |
| `drawerIn` | `translateX(100%)→0`, .38 s `cubic-bezier(.2,.8,.2,1)`; sale en .2 s. Fondo `navy-950` al 55 %, sin desenfoque |
| `toastIn` / `toastOut` | `translateY(16px) scale(.96)→none`, .35 s; sale en .18 s |
| `shimmer` | brillo que cruza los esqueletos de carga, 1.6 s lineal |
| `flash` | fondo `blue-100 → transparent`, 2.2 s (fila recién creada / entrada de auditoría nueva) |
| `pulseDot` | halo verde de 8 px en estado «Operativo», 2.2 s infinito |
| `popIn` | `scale(.6→1.08→1)` para tarjetas de insignias y confirmación |
| `spin` | login: órbitas 60 s / 140 s; spinner de guardado .7 s |
| Hover | nav `translateX(3px)` + fondo `rgba(255,255,255,.08)`; botón `translateY(-2px)`; checkbox `scale(1.12)`; fila → `row-hover` |
| Switch | pista .22 s; knob `cubic-bezier(.3,1.4,.5,1)` desplazando 18 px |

---

> **Estado:** las 7 pantallas de este documento están implementadas y conectadas al backend (ver `AGENTS.md` §«Cómo está armado el panel»). Diferencias respecto al mockup: el drawer «Nuevo usuario» muestra la **contraseña temporal** que genera el servidor (una sola vez); la tabla de usuarios permite **cambiar el rol**; Parámetros añade «Evaluar alertas ahora»; Auditoría añade el filtro «Negocio» y paginación; las listas del resumen usan datos reales (emprendimientos activos y alertas abiertas en lugar de «acciones auditadas»).
>
> **Implementado y conectado al backend:** `/login` y `/register` (feature `auth`). La cuenta que crea el registro es de **emprendedor** (sin acceso al panel hasta que un administrador le asigne un rol); el login rechaza a los emprendedores. Aviso de éxito en `/login?registrado=1`.
> El registro no existía en el mockup: se diseñó con
> el mismo layout (título «Solicitar acceso», nombre, correo, contraseña y confirmación, aviso de revisión).

## 4. Pantalla 1 — Ingreso administrador (`/login`)

Layout: dos paneles en `flex-wrap`, `min-height: 100vh`; en < ~1040 px se apilan.

**Panel de marca** (izquierda, `flex: 1 1 560px`, fondo `navy-950`, texto blanco, `padding: 56px 64px`,
`overflow: hidden`, columna con `justify-content: space-between`):

1. Cabecera: logo CIE-U 56×56 (radio 14, anillo `rgba(255,255,255,.18)`) + texto Sora 600 15 px
   «Centro de Innovación y / Emprendimiento Universitario».
2. Centro (`max-width: 560px`):
   - Píldora `rgba(255,255,255,.1)`: punto `#FF5468` 8 px + «ADMINISTRADOR DEL SISTEMA» (13 px, 600, .04em).
   - `h1` «Seguimiento de emprendedores, bajo control.»
   - Párrafo 17 px `#C9D6F5`: «Gestiona usuarios, roles, permisos y parámetros del acompañamiento a emprendimientos del CIE-U.»
3. Pie: «FCEE · UAGRM · Santa Cruz, Bolivia» (14 px, `#B4C4EE`).
4. **Decoración SVG** (aria-hidden, esquina inferior derecha, 760×760, `right:-180px; bottom:-160px`):
   tres órbitas concéntricas (r 120 azul, r 210 punteada blanca, r 290 azul tenue) con satélites
   (rojo, blanco, azul) que giran a 60 s / 90 s (inverso) / 140 s, y un núcleo `#0A3A8F` (r 56) que pulsa
   4 s. Es el motivo gráfico de la marca (órbitas = acompañamiento).

**Formulario** (derecha, `flex: 1 1 480px`, centrado, `max-width: 420px`):

- `h2` «Acceso administrativo» + «Ingresa con tu cuenta institucional para continuar.»
- Campo **Correo electrónico** (`type=email`, `autocomplete=username`, placeholder `admin@uagrm.edu.bo`).
- Campo **Contraseña** (`autocomplete=current-password`, placeholder `••••••••••`) con botón
  de texto «Mostrar / Ocultar» (alterna `type`, objetivo ≥ 44 px, color `blue-600`).
- Inputs: alto 52 px, `padding: 0 16px`, borde `1.5px border-strong`, radio 12, fondo blanco.
- Botón primario «Ingresar al panel» + flecha derecha: alto 54, radio 12, `blue-600`, 16 px/700.
- Enlace «Recuperar credenciales» centrado (≥ 44 px de alto).
- Aviso informativo (`blue-50`, radio 12, padding 16): icono candado `blue-600` + «Acceso protegido por
  autenticación. Las acciones sensibles quedan registradas para auditoría.»

Comportamiento real: `POST /api/v1/auth/login` → JWT; errores con la forma global
`{"error": {...}}`; mensaje de error de formulario en `error` (`#B3122D`). El mockup solo navega al panel.

---

## 5. Shell de la aplicación (`(app)/layout.tsx`)

Layout `flex-wrap`, `min-height: 100vh`, fondo `surface-muted`.

**Sidebar** (264 px fijo, fondo `navy-950`, `padding: 28px 16px`, columna, `gap: 28px`):

- Marca: logo 44×44 (radio 11) + «CIE-U» (Sora 700 17 px) y «Administración» (13 px `#B4C4EE`).
- Navegación (`aria-label="Secciones"`), ítems de 46 px de alto, radio 12, icono 20 px + etiqueta 15 px/600:

| Ítem | Etiqueta | Icono lucide equivalente |
|---|---|---|
| `panel` | Resumen | `layout-dashboard` |
| `usuarios` | Usuarios | `users` |
| `roles` | Roles y permisos | `shield-check` |
| `params` | Parámetros | `sliders-horizontal` |
| `cat` | Catálogos y XP | `award` |
| `aud` | Auditoría | `clipboard-list` |
| `cuenta` | Mi cuenta (sin permiso: todo el personal) | `user-round` |
| `asig` | Asignaciones (`asesorias:registro`; oculto al rol asesor) | `user-check` |
| `disp` | Mi disponibilidad (`asesorias:modificacion`: el asesor) | `calendar-clock` |
| `ses` | Sesiones (`asesorias:consulta`) | `calendar-days` |

  Activo: fondo `rgba(255,255,255,.14)`, texto blanco, `aria-current="page"`, punto `#FF5468` 6 px a la derecha.
  Inactivo: texto `#C9D6F5`. Hover: ver §3.4.
- Pie: tarjeta de usuario (`rgba(255,255,255,.07)`, radio 14): avatar circular 40 px `blue-600` con iniciales,
  nombre (14/600) y rol (12 px `#B4C4EE`) + enlace «Cerrar sesión» (icono log-out, 44 px).

**Cabecera de página** (sin animación propia: ya entra con la transición de página): `h1` + subtítulo a la izquierda; acciones a la derecha:
«Nuevo usuario» (solo Usuarios) y «Exportar CSV» (solo Auditoría).

| Vista | Título | Subtítulo |
|---|---|---|
| Resumen | Resumen de la plataforma | Supervisa cuentas, servicios y la actividad administrativa reciente. |
| Usuarios | Usuarios | Registra, modifica, habilita o deshabilita las cuentas de la plataforma. |
| Roles | Roles y permisos | Define qué puede consultar, registrar, modificar y administrar cada rol. |
| Parámetros | Parámetros de seguimiento | Reglas que usa el sistema para detectar inactividad y riesgo de deserción. |
| Catálogos | Catálogos y gamificación | Etapas del ciclo de vida, retos, recompensas XP e insignias. |
| Auditoría | Auditoría | Registro de acciones sensibles realizadas en el sistema. |
| Mi cuenta | Mi cuenta | Consulta tus datos y cambia tu contraseña de acceso. |
| Asignaciones | Asignaciones | Habilita asesores y asígnalos a los emprendimientos que acompañarán. |
| Disponibilidad | Mi disponibilidad | Define cuándo puedes atender mentorías; los emprendedores asignados agendan dentro de estos horarios. |
| Sesiones | Sesiones | Mentorías por estado y periodo; registra lo que ocurrió, recomienda y deja compromisos. |

**Toast global**: `position: fixed; right/bottom: 28px`, `max-width: 420px`, fondo `navy-900`, texto blanco 14 px,
check verde en círculo de 26 px. Se oculta a los 3.2 s. `role="status"`.

**Responsive**: el sidebar es fijo en escritorio; el contenido tiene `flex: 999 1 560px; min-width: 0`.
Tablas con `overflow-x: auto` y `min-width` interno. En móvil el sidebar debería colapsar (no diseñado).

---

## 6. Pantalla 2 — Resumen (`/`)

1. **KPIs** (`grid auto-fit minmax(220px,1fr)`, gap 16). Tarjeta blanca, borde `border`, radio 16,
   padding `20px 22px`: etiqueta 14/600 `muted`, valor Sora 38/700, nota 13 px.

| KPI | Valor | Nota | Color del valor |
|---|---|---|---|
| Usuarios registrados | total | Todos los roles | `ink` |
| Cuentas habilitadas | habilitadas | Con acceso a la plataforma | `green-800` |
| Cuentas deshabilitadas | deshabilitadas | Sin acceso | `red-800` |
| Acciones auditadas | nº de eventos | Registro de acciones sensibles | `blue-600` |

2. Fila `flex-wrap` gap 24:
   - **Usuarios por rol** (`flex: 1.4 1 420px`): una barra por rol; etiqueta + conteo; pista `#EEF2FA` de
     12 px, relleno con el color del rol, ancho = `conteo / máximo`. Subtítulo «Distribución de cuentas registradas en la plataforma.»
   - **Estado de la plataforma** (`flex: 1 1 320px`): lista con punto verde pulsante 10 px, nombre (15/600),
     descripción (13 px) y píldora «Operativo» (`green-100`/`green-800`). Servicios: *API REST (FastAPI)* —
     Autenticación y lógica de negocio; *PostgreSQL* — Base de datos central; *Motor de IA (Ollama + RAG)* —
     Asistente y búsqueda semántica; *Sincronización móvil* — Registros guardados sin conexión.
3. **Actividad reciente**: últimas 4 acciones de auditoría; fila = hora (96 px, 13 px muted) +
   «**Actor** · acción · objeto». Botón ghost «Ver auditoría» (44 px) que navega a `/audit`.

---

## 7. Pantalla 3 — Usuarios (`/users`)

- **Barra de herramientas**: buscador (`type=search`, alto 48, icono lupa a 16 px, `max-width: 420px`,
  `label` oculto «Buscar usuarios», placeholder «Buscar por nombre o correo») + filtros-píldora
  (Todos, Administrador, Coordinador, Asesor / Mentor, Emprendedor; alto 44; activo = fondo `navy-900`,
  texto blanco; `aria-pressed`).
- **Tabla** (tarjeta con `overflow-x:auto`, `min-width: 880px`, columnas
  `minmax(240px,2.2fr) 170px 200px 150px`, gap 16, padding `12px 24px`):

| Columna | Contenido |
|---|---|
| Usuario | Avatar circular 42 px con iniciales + nombre (15/600, elipsis) + correo (13 px muted) |
| Rol | Píldora con colores del rol |
| Estado de la cuenta | Switch + texto «Habilitada» (verde) / «Deshabilitada» (rojo) |
| Último acceso | «Hoy, 08:12», «Ayer», «Hace 3 días», «Nunca» |

  Cabecera: fondo `surface-head`, MAYÚSCULAS. Filas: `fadeUp` escalonado 45 ms.
- **Switch** (patrón reutilizable): `<button role="switch" aria-checked>` de 56×44 (área clic); pista 44×26,
  `blue-600` encendido / `#9AA6C4` apagado; knob blanco 20×20 a 3 px. La cuenta del propio admin (id 1) queda
  bloqueada: `disabled`, `opacity .45`, `cursor: not-allowed`.
- Vacío: «Ningún usuario coincide con la búsqueda.» (centrado, 15 px, muted).
- Nota al pie (13 px): «Los cambios de estado quedan registrados en la auditoría. No puedes deshabilitar tu propia cuenta.»
- Al alternar: toast «Cuenta deshabilitada/habilitada: {nombre}. Registrado en auditoría.» y nueva entrada de auditoría.

### Drawer «Nuevo usuario»

Overlay `fixed inset-0`, scrim `rgba(2,31,80,.55)` (clic cierra), panel derecho `max-width: 460px`, alto 100%, blanco.
`role="dialog" aria-modal="true"`.

- Cabecera: «Nuevo usuario» (Sora 20) + botón cerrar 44×44 (`surface-muted`, radio 12).
- Campos: **Nombre completo** (placeholder «Nombre y apellidos»; error «Este campo es obligatorio.»),
  **Correo electrónico** (placeholder `nombre@uagrm.edu.bo`; error «Ingresa un correo válido.» con regex `^\S+@\S+\.\S+$`),
  **Rol asignado** (lista de 4 radio-botones de 56 px: círculo 22 px con punto `blue-600`; seleccionado =
  borde `blue-600` + fondo `blue-50`; por defecto Emprendedor).
- Errores: borde `#B3122D`, mensaje 13/600 con `fadeUp`; se limpian al escribir.
- Pie: «Cancelar» (ghost, flex 1) y «Registrar usuario» (primario, flex 1.4).
- Al crear: cierra, fila nueva arriba con `flash`, limpia filtros, toast «Usuario registrado: {nombre}.».

---

## 8. Pantalla 4 — Roles y permisos (`/roles`)

Dos columnas `flex-wrap`, gap 24.

- **Selector de rol** (`flex: 0 1 300px`): tarjetas-botón (`aria-pressed`): nombre (Sora 16/600) + «N usuarios» y
  descripción (13 px). Seleccionada = borde 2 px `blue-600` + fondo `blue-50`.

| Rol | Descripción |
|---|---|
| Administrador | Gestiona usuarios, roles, permisos y configuración general. |
| Coordinador | Supervisa emprendimientos, indicadores y alertas del CIE-U. |
| Asesor / Mentor | Registra asesorías, recomendaciones y compromisos asignados. |
| Emprendedor | Usuario de la app móvil: progreso, tareas y asistente IA. |

- **Matriz de permisos** (`flex: 1 1 560px`, `min-width: 640px` con scroll): título «Permisos · {rol}» y
  «Se aplican en el siguiente acceso de los usuarios con este rol.». Columnas `minmax(220px,1fr) repeat(4,100px)`:
  **Módulo · Consulta · Registro · Modificación · Administrativo**. Cada celda es un checkbox de 44×44 con caja
  visual de 24 px (radio 7, borde 2 px, marcado = `blue-600` + check blanco). `aria-label` = «{Acción} en {Módulo}».
  Módulos: Usuarios y roles · Emprendedores y emprendimientos · Asesorías y mentorías · Seguimiento y etapas ·
  Asistente inteligente · Indicadores y reportes · Configuración del sistema.
- Códigos de permiso: `c` consulta, `r` registro, `m` modificación, `a` administrativo.
  Valores por defecto (módulo → rol):

| Módulo | Admin | Coord | Asesor | Emprend. |
|---|---|---|---|---|
| usuarios | crma | — | — | — |
| emprend | c | crm | c | cr |
| asesorias | c | cr | crm | c |
| seguimiento | c | crm | cr | cr |
| ia | — | c | — | cr |
| reportes | c | cr | — | — |
| config | crma | cm | — | — |

- **Barra de cambios sin guardar** (aparece con `slideUp` si hay diferencias): fondo `amber-50`, borde superior
  `#F0DDA0`, «Hay cambios sin guardar en {rol}.» + «Descartar» (ghost) + «Guardar cambios» (primario con spinner
  de 16 px y texto «Guardando…» ~0.9 s). Al guardar: toast «Permisos guardados. Se aplicarán en el siguiente acceso.» y auditoría
  «Modificó permisos · Rol {rol}».

---

## 9. Pantalla 5 — Parámetros de seguimiento (`/settings/tracking`)

Dos columnas: formulario (`flex: 1 1 520px`) y resumen lateral (`flex: 0 1 340px`).

1. **Periodo de inactividad**: descripción «Los emprendedores sin actividad relevante durante este periodo se
   marcan para seguimiento. No se suspende ni elimina ninguna cuenta.» Valor grande a la derecha
   (Sora 34 `blue-600` + «días»). `input[type=range]` 3–30, paso 1 (alto 44, `accent-color: blue-600`);
   extremos «3 días» / «30 días». Por defecto **14**.
2. **Caída del índice de sentimiento**: «Señal complementaria para detectar cambios negativos persistentes. No
   constituye un diagnóstico y solo es visible para personal autorizado.» Slider «Variación negativa mínima»
   10–60 % paso 5 (defecto **25 %**) y *stepper* «Periodos consecutivos para activar» con botones − / + de
   44×44 (rango 1–4, defecto **2**).
3. **Alertas por riesgo de deserción**: «Una alerta no modifica automáticamente el estado del emprendimiento.»
   Tres switches: *Notificar al Coordinador del CIE-U* (activo), *Notificar al asesor asignado* (activo),
   *Incumplimiento de compromisos* (apagado).
4. **Panel lateral «Configuración que se aplicará»** (fondo `navy-900`, texto blanco, radio 16): eyebrow +
   «Revisa los valores antes de confirmar.» y pares clave/valor: *Inactividad* `N días`, *Caída de sentimiento*
   `≥ N %`, *Periodos consecutivos* `N`, *Alertas activas* `N de 3`. Botón «Confirmar y aplicar»
   (fondo `#FF5468`, texto `#2A0008`). Tras confirmar se sustituye por un aviso verde («Configuración aplicada y
   registrada en la auditoría.») hasta el siguiente cambio. Toast «Parámetros de seguimiento actualizados.»
   Es un patrón de **confirmación explícita**: mover un control nunca aplica nada por sí solo.

---

## 10. Pantalla 6 — Catálogos y XP (`/catalogs`)

Pestañas-botón (alto 46, radio 12, activa = `blue-600` + texto blanco): **Etapas · Retos · Insignias**.

- **Etapas** (lista en tarjeta): círculo numerado 40 px (`blue-50`/`blue-600`, Sora), nombre (16/600),
  «N retos asociados», etiqueta «Activa/Inactiva» y switch. Etapas: 1 Preincubación, 2 Incubación, 3 Crecimiento, 4 Graduación.
- **Retos** (tabla `min-width: 720px`, columnas `minmax(260px,2fr) 160px 190px`): Reto · Etapa (píldora `blue-50`/`#12308A`) ·
  Recompensa (XP) con stepper −/+ de 10 en 10 (mínimo 0, valor Sora 17/700). Nota: «El XP solo se asigna una vez
  por reto cumplido; el sistema no duplica recompensas.»

| Reto | Etapa | XP |
|---|---|---|
| Completar el perfil del emprendimiento | Preincubación | 50 |
| Entrevistar a 5 clientes potenciales | Preincubación | 120 |
| Definir la propuesta de valor | Preincubación | 100 |
| Construir un prototipo mínimo | Incubación | 150 |
| Registrar ventas de prueba | Incubación | 200 |
| Presentar el plan financiero | Crecimiento | 250 |

- **Insignias** (`grid auto-fit minmax(240px,1fr)`): icono 52 px (radio 14, fondo de color) + nombre (Sora 16/600),
  criterio (13 px) y chip `+N XP` (`red-100`/`red-800`).

| Insignia | Criterio | XP | Color |
|---|---|---|---|
| Primer paso | Completa tu primer reto. | 25 | `#1F4FD6` |
| Constancia | Accede a la app 7 días seguidos. | 40 | `#0A1A44` |
| Validador | Completa las entrevistas con clientes. | 80 | `#D61F3A` |
| Bitácora al día | Registra avances cada semana durante un mes. | 60 | `#0E7A4F` |
| Conector | Asiste a tu primera mentoría. | 50 | `#7A3FD1` |
| Graduado | Completa todas las etapas del programa. | 300 | `#B26A00` |

---

## 11. Pantalla 7 — Auditoría (`/audit`)

- Filtros-píldora: Todos · Usuarios · Roles · Configuración · Accesos (activo = `navy-900`).
- Tabla (`min-width: 820px`, `130px 190px minmax(280px,1fr) 120px`): **Hora · Actor · Acción · Resultado**.
  Acción = «acción · *objeto*» (objeto en muted). Resultado = píldora `Exitoso` (verde) / `Rechazado` (rojo).
- Las entradas nuevas entran arriba con `slideUp` + `flash`; el resto con `fadeUp` escalonado (35 ms).
- «Exportar CSV» (ghost, icono download) → toast «Exportación de auditoría generada.»
- Eventos de ejemplo: inicio de sesión, intento de acceso fallido, creación de usuario, modificación de
  permisos, cambio de parámetro (`Periodo de inactividad: 10 → 14 días`), deshabilitación de cuenta,
  actualización del XP de un reto. Categorías: `accesos`, `usuarios`, `roles`, `config`.

---

## 12. Componentes reutilizables

| Componente | Base propuesta | Notas |
|---|---|---|
| Botón primario / ghost / icono | `components/ui/button.tsx` (shadcn) | Añadir variantes `primary` (blue-600), `ghost` (borde `border-strong`), `accent` (red-400). Alto mínimo 44–54 |
| Input / Label / mensaje de error | shadcn `input`, `label` | Alto 48–52, radio 12, anillo de foco de 4 px |
| Switch | shadcn `switch` (Base UI) | Pista 44×26, knob 20; área clic 56×44 |
| Checkbox | shadcn `checkbox` | Caja 24 px, radio 7, área 44×44 |
| Slider | shadcn `slider` | Alto de área 44, color `blue-600` |
| Stepper −/+ | propio | Botones 44×44 en `surface-muted`, valor central |
| Píldora / badge | shadcn `badge` | Radio 999, 13/700, variantes de rol, éxito, error, info, aviso |
| Tarjeta | shadcn `card` | Radio 16, borde `border`, hover con sombra suave |
| Tabla en rejilla | propio (`grid`) | Cabecera `surface-head` MAYÚSCULAS, `overflow-x:auto` |
| Drawer lateral | shadcn `sheet` | Derecha, 460 px, scrim navy |
| Pestañas / filtros-píldora | shadcn `tabs` / `toggle-group` | `aria-pressed` |
| Toast | `sonner` o propio | Abajo-derecha, fondo `navy-900` |
| Avatar | shadcn `avatar` | Iniciales, paleta cíclica |

Instalar con `pnpm dlx shadcn@latest add <comp>`; **no** meter lógica de negocio en `components/ui/`
(regla web §4.4). Las composiciones propias van en `features/<f>/components/` o `components/layout/`
(sidebar, header, shell).

---

## 13. Mapeo a la arquitectura feature-based

Reglas aplicables: nombres de feature = nombres de módulo del backend (global §4.6); `app/` solo enruta (web §4.1);
imports entre features por barrel (web §4.2).

```
app/
├── (public)/login/page.tsx            → compone features/auth
└── (app)/
    ├── layout.tsx                     → shell: components/layout (sidebar + header + toaster)
    ├── page.tsx                       → Resumen
    ├── users/page.tsx                 → features/users
    ├── roles/page.tsx                 → features/users (roles y permisos)
    ├── settings/tracking/page.tsx     → features/alerts   (propuesta)
    ├── catalogs/page.tsx              → features/gamification (propuesta; etapas viven en ventures)
    └── audit/page.tsx                 → features/audit    (propuesta)
components/layout/                     → AppSidebar, PageHeader, Toaster
```

Features: `auth` y `users` **ya están previstas** en `AGENTS.md`. `alerts`, `gamification`, `audit`,
`ventures` e `indicators` coinciden con módulos del backend pero **no están en la tabla de features**:
hay que proponerlas y registrarlas en `AGENTS.md` en el mismo commit en que se creen (regla global §4.4).
Los mocks de este diseño hablan de «roles» y «permisos» → tablas `rol`, `permiso`, `rol_permiso`, `rol_usuario`
del módulo `users`; «auditoría» → `bitacora`; «retos / insignias / XP» → `retos`, `insignias`, `movimientos_xp`;
«alertas por deserción» → `alertas`, `tipos`; «etapas» → `etapas`.

Frontera cliente/servidor: casi todo el panel es interactivo (switches, filtros, drawer). Mantén
`page.tsx` y `layout.tsx` como Server Components y marca `'use client'` solo en las hojas
(`UsersTable`, `PermissionMatrix`, `TrackingForm`, `NewUserDrawer`…). Los filtros pueden vivir en la URL
(`searchParams`) o en un store de zustand por feature (`features/users/stores/`); el estado de servidor
(usuarios, auditoría) **no** va a zustand.

---

## 14. Contrato con el backend

Todo dato de las tablas anteriores sale de `/api/v1` (global §5). Referencias de forma, no implementadas aún:

- Lista de usuarios con paginación `?page=&page_size=` → `{items, page, page_size, total}`; búsqueda `q` y filtro `rol`.
- Habilitar/deshabilitar usuario, crear usuario (nombre, correo, rol), matriz de permisos por rol, parámetros
  de seguimiento, catálogos (etapas, retos con XP, insignias) y bitácora (con filtro por categoría y export CSV).
- IDs como `number` (BIGINT), fechas ISO-8601 UTC (la UI las formatea a «Hoy, 08:12», «Ayer», «Hace N días»).
- Cada acción sensible escribe en `bitacora`; la UI lo comunica («Registrado en auditoría»).
- Los tipos TypeScript se derivan del OpenAPI (`/api/v1/openapi.json`); los nombres de campo siguen el esquema
  `cieu` en español (global §4.9).

---

## 15. Accesibilidad (checklist del diseño)

- [ ] Todo control interactivo ≥ 44×44 px (los switches y checkboxes tienen área de clic mayor que su dibujo).
- [ ] Texto ≥ 4.5:1: usar los pares fondo/texto listados (p. ej. `#8F0F25` sobre `#FFE3E8`, `#0A5C39` sobre `#DDF3E7`).
- [ ] `label` asociado a cada input; buscador con label oculto; botones solo-icono con `aria-label`.
- [ ] Switches con `role="switch"` + `aria-checked`; filtros con `aria-pressed`; nav con `aria-current="page"`.
- [ ] Drawer con `role="dialog"` + `aria-modal`, foco atrapado y cierre con Escape (mejora sobre el mockup).
- [ ] Toasts con `role="status"`.
- [ ] Estados que se distinguen por color también llevan texto («Habilitada/Deshabilitada», «Exitoso/Rechazado»).
- [ ] `prefers-reduced-motion` desactiva animaciones y transiciones.
- [ ] Iconos decorativos con `aria-hidden="true"`.

---

## 16. Activos y notas pendientes

- **Logo del CIE-U**: ya en `public/brand/cie-u-logo.png`. Se muestra cuadrado con esquinas redondeadas y un anillo `rgba(255,255,255,.18)`.
- **Fuentes**: Sora y DM Sans vía `next/font/google` (ya configuradas en `app/layout.tsx`).
- **Iconos**: el mockup usa trazos SVG tipo Feather; usar su equivalente en `lucide-react` (stroke 2).
- **Datos de ejemplo** (usuarios, auditoría) son ficticios del mockup; no sembrarlos en producción.
- Lo no diseñado y que habrá que decidir con el usuario: recuperación de credenciales, edición/eliminación de
  usuario, estados de carga y error de red, paginación de tablas, modo oscuro, sidebar colapsable en móvil,
  crear/editar etapas, retos e insignias (el mockup solo permite activar etapas y ajustar XP).
