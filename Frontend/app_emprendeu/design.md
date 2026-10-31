# App móvil EmprendeU (CIE-U) — Diseño de la app del emprendedor

> Fuente: mockup «CIE-U · Mockups Administrador Web y App Móvil» (artboards `Móvil · 1…6`, lienzo 390×844).
> Lee antes `AGENTS.md` (arquitectura feature-first por capas) y `../../AGENTS.md` (reglas globales).
> Este documento describe **cómo se ve y se comporta** la app; el `AGENTS.md` dice **dónde va el código**.
> Es prescriptivo: hoy `lib/main.dart` sigue siendo el contador de Flutter.

---

## 1. Alcance

App para el rol **Emprendedor** (estudiante/emprendedor acompañado por el CIE-U). Objetivo real: Android e iOS.
Marco de diseño: **390×844 dp**, sin status bar dibujada (el sistema la pinta; ver §4.1 para el inset superior).

| # | Pantalla | Ruta propuesta | Qué hace |
|---|---|---|---|
| 1 | Ingreso | `/login` | Correo + contraseña, «¿Olvidaste tu contraseña?», «Regístrate» |
| 2 | Inicio | `/home` | Saludo, estado de red/sincronización, progreso XP, siguiente reto, compromisos, avances |
| 3 | Camino | `/journey` | Mapa gamificado de retos con hoja de detalle |
| 4 | Coach IA | `/coach` | Chat con asistente basado en la base documental del CIE-U |
| 5 | Mentorías | `/mentoring` | Agendar (mentor → fecha → horario) y «Mis sesiones» |
| 6 | Perfil y logros | `/profile` | Identidad, XP, insignias, historial, sincronización, cerrar sesión |

Navegación principal: barra inferior de **5 pestañas** (Inicio, Camino, Coach IA, Mentorías, Perfil) visible
en las pantallas 2–6. La pantalla 1 es previa a la sesión.

---

## 2. Principios

- **Una mano, pulgar primero**: objetivos ≥ 44 dp (la mayoría 48–56), acciones principales abajo (hojas inferiores,
  barra de confirmación fija), navegación en la parte inferior.
- **Motivación sin ruido**: gamificación (XP, camino, insignias) con colores claros y animaciones breves; el
  rojo es acento, no alarma.
- **Honestidad del asistente**: el Coach siempre advierte que no sustituye a un mentor y cita su fuente; si no
  sabe, lo dice y ofrece derivar a una persona.
- **Offline-first visible**: el usuario ve en todo momento si está en línea, qué quedó pendiente y cuándo se
  sincroniza.
- **Accesible**: contraste ≥ 4.5:1, foco visible, semántica en cada control, `reduce motion` respetado,
  nada se comunica solo con color.
- Idioma de la UI: **español**; identificadores en inglés (regla global §4.9).

---

## 3. Tokens de diseño

Implementarlos en `lib/app/theme/` como `ThemeData` + extensiones tipadas (`AppColors`, `AppSpacing`,
`AppRadii`, `AppText`). **Prohibido** `Color(0xFF…)` suelto en widgets: todo color sale del tema.

### 3.1 Color

| Token (`AppColors`) | Hex | Uso |
|---|---|---|
| `navy950` | `#021F50` | Fondo de la pantalla de ingreso, scrim (`#021F50` al 55 %) |
| `navy900` | `#0A1A44` | Tarjetas oscuras (progreso, XP del perfil, CTA del coach), píldora de XP, segmento activo, avatar |
| `primary` (blue 600) | `#1F4FD6` | Botones primarios, pestaña activa, burbuja del usuario, nodo «en curso», foco |
| `blue50` | `#EAF0FF` | Fondo del ítem activo de la barra, chips informativos |
| `blue100` | `#DCE6FF` | Chip «En curso», chip de etapa, avatar de mentor |
| `blue800` | `#12308A` | Texto sobre `blue50/100` |
| `blue900` | `#0F2F8C` | Texto en chip «Incubación» |
| `blueRing` | `#7FA6FF` | Anillo y barra de progreso sobre fondo oscuro |
| `blueTrack` | `#9DB7F5` | Camino punteado (tramo pendiente) |
| `onNavyMuted` | `#C9D6F5` | Texto secundario sobre navy; `#E3EAFB` etiquetas del login; `#9FB4EE` placeholder del login |
| `accent` | `#D61F3A` | Insignia obtenida, satélite decorativo |
| `accentSoft` | `#FF5468` / `#FF8A9A` | Satélite del login, icono de rayo, anillo de foco sobre navy |
| `accentTint` | `#FFE3E8` | Chip «+N XP», chip «Nivel 2» |
| `accentOn` | `#8F0F25` | Texto sobre `accentTint` |
| `success` | `#0E7A4F` | Camino/nodo cumplido, check, «En línea», botón «Marcar como cumplido» |
| `successDark` | `#0A5C39` | Texto sobre éxito claro |
| `successTint` | `#DDF3E7` | Fondos de éxito («En línea», «Sincronizado», aviso verde) |
| `warning` | `#B26A00` | Punto de «Sin conexión» |
| `warningTint` | `#FFF0CC` | «Sin conexión», «Pendiente de sincronizar», «1 compromiso» |
| `warningTint2` | `#FFF6DC` | Aviso del Coach |
| `warningOn` | `#5E3F00` / `#6B4700` | Texto sobre warning |
| `ink` | `#0E1730` | Texto principal |
| `ink2` | `#2B3552` | Texto secundario fuerte |
| `muted` | `#4A5675` | Texto de apoyo, iconos inactivos |
| `bg` | `#F3F6FD` | **Fondo de pantalla** |
| `surface` | `#FFFFFF` | Tarjetas, barra inferior, cabecera del coach |
| `border` | `#E1E6F0` | Bordes de tarjetas y barra |
| `borderStrong` | `#CBD3E6` | Bordes de inputs/botones secundarios, manija de hojas |
| `divider` | `#EEF2FA` | Separadores de lista |
| `neutralFill` | `#E7ECF6` | Segmento contenedor, nodo bloqueado, insignia bloqueada |
| `disabledFill` | `#EEF1F7` | Mentor/horario no disponible |
| `outlineOff` | `#9AA6C4` | Borde de checkbox sin marcar |

**Chips de estado de reto**

| Estado | Fondo | Texto |
|---|---|---|
| Cumplido | `#DDF3E7` | `#0A5C39` |
| En curso | `#DCE6FF` | `#12308A` |
| Bloqueado | `#E7ECF6` | `#2B3552` |

**Avatares de mentor**: Marcelo `#DCE6FF/#0F2F8C`, Daniela `#FFE3E8/#8F0F25`, Andrés (bloqueado) `#E7ECF6/#4A5675`.
Iniciales = primera letra de las dos primeras palabras.

### 3.2 Tipografía

| Rol | Familia | Pesos |
|---|---|---|
| Títulos, cifras, números de fecha | **Sora** | 500, 600, 700 |
| Cuerpo y controles | **DM Sans** | 400, 500, 600, 700 |

Se usa el paquete **`google_fonts`** (ya en `pubspec.yaml`), que descarga y cachea las fuentes en runtime. En tests
se desactiva con `AppTheme.light(useGoogleFonts: false)`. Alternativa futura si se necesita offline desde el primer
arranque: empaquetar las fuentes como assets.

| Uso | Familia | Tamaño | Peso | Notas |
|---|---|---|---|---|
| Hero del login | Sora | 32 | 700 | altura 1.12, tracking −0.02em |
| Título de pantalla (`Mi camino`, `Mentorías`, `Hola, Camila`) | Sora | 26 | 700 | tracking −0.02em |
| Perfil: nombre | Sora | 22 | 700 | |
| Título de hoja | Sora | 20–22 | 600–700 | |
| Cifra de XP grande | Sora | 26 | 700 | anillo: 26; perfil: 26 + «XP» 14/600 |
| Subtítulo de sección | Sora | 17–18 | 600–700 | |
| Etiqueta de nodo | Sora | 14 | 600 | altura 1.25 |
| Cuerpo | DM Sans | 15–16 | 400–600 | altura 1.4–1.5 |
| Apoyo / fecha | DM Sans | 13–14 | 400–600 | |
| Chips | DM Sans | 12–13 | 700 | |
| Etiqueta de pestaña | DM Sans | 12 | 600 (700 activa) | |
| Overline «SIGUIENTE RETO», «DETALLE» | DM Sans | 12 | 700 | MAYÚSCULAS, tracking .08em |

> Escalado de texto del sistema: la UI debe tolerar `textScaler` hasta 1.3 sin recortar (usar `Flexible`,
> `Wrap`, alturas mínimas en vez de fijas en tarjetas de texto).

### 3.3 Espaciado, radios y elevación

- Márgenes laterales de pantalla: **20 dp** (login 28). Separación vertical entre bloques: 18–22. Gaps internos 8–16.
- Padding superior de las pantallas con cabecera propia: **56 dp** (reserva para la barra de estado y el notch;
  en Flutter usar `SafeArea` + este valor como mínimo estético, no un número mágico).
- **Radios**: píldora `999`; tarjeta grande `20–24`; tarjeta `16–18`; botón/input `14`; botón secundario `12`; hoja
  inferior `26` arriba; nodo del camino círculo 64; avatar círculo; insignia `16`; checkbox `9`; mini-calendario `16`; barra de segmentos `16` (interior `12`).
- **Elevación**: casi plana (bordes de 1 px `border`). Sombras solo en: nodo del camino
  (`0 10–12px 20–24px -8px` del color del nodo al ~60 %), burbuja de XP flotante
  (`0 14px 30px -10px rgba(14,122,79,.7)`) y hover del CTA de login. No usar `elevation` de Material por defecto.
- **Foco**: anillo 3 dp `primary` offset 2–3 (sobre navy, `#FF8A9A`). Campo enfocado: borde `primary` + halo 4 dp al 16 %
  (en login: borde blanco + fondo `rgba(255,255,255,.14)`).

### 3.4 Movimiento

Duraciones cortas (150–400 ms) y curvas tipo `Curves.easeOutCubic`; los acentos celebratorios hasta 1.4 s.

| Animación | Dónde |
|---|---|
| `fadeUp` (opacity + 14–20 dp) escalonado ~80 ms | Entrada de secciones en todas las pantallas |
| `popIn` (escala .5→1.08→1) | Logo del login, insignias, tarjeta de sesión agendada |
| `ripple` (anillo que se expande y desvanece) | Logo del login (2.8 s), nodo actual del camino (2.2 s), check de «Mentoría agendada» |
| Órbitas giratorias (70 s / 110 s) | Fondo del login; anillo punteado del avatar del perfil (14 s) |
| Anillo de progreso (`stroke-dashoffset`) | Inicio: 1.4 s, retrasado .3 s |
| Barra de XP `scaleX` | Perfil: 1.2 s |
| Camino verde que se dibuja | Camino: 1.3 s al montar y tras cumplir un reto |
| Burbuja «+N XP» flotante | Sube 70 dp y desaparece en 2 s |
| Hoja inferior `sheetUp` | .38 s `cubic-bezier(.2,.8,.2,1)` |
| Puntos de «escribiendo» | 1.2 s por punto, desfase .2 s |
| Brillo de insignia obtenida (`shine`) | Barrido diagonal cada 3.2 s |
| Pulsar | `scale(.97)` / `.94` al presionar botones |

Con `MediaQuery.disableAnimations` / reduce motion: sin órbitas, ripple ni brillos; transiciones instantáneas.

---

## 4. Componentes compartidos

### 4.1 Barra de navegación inferior

`height: 84` (incl. 18 de inset inferior), fondo blanco, borde superior 1 px `border`, 5 columnas iguales.
Cada ítem: icono 22 + etiqueta 12, altura mínima 56. **Activo**: texto `primary` 700 y *píldora indicadora*
56×30 radio 15 con fondo `blue50` detrás del icono; inactivo: `muted`, 600. `aria-current="page"`.

| Pestaña | Icono Material/Lucide equivalente | Destino |
|---|---|---|
| Inicio | `home` | `/home` |
| Camino | `flag` | `/journey` |
| Coach IA | `message-square` | `/coach` |
| Mentorías | `calendar` | `/mentoring` |
| Perfil | `user` | `/profile` |

Implementar con `go_router` `StatefulShellRoute.indexedStack` + un `NavigationBar` personalizado en
`shared/widgets/`. Conserva el estado de cada pestaña.

### 4.2 Botones

| Variante | Medidas | Estilo |
|---|---|---|
| Primario | alto 48–56, radio 14 | `primary`, texto blanco 15–17/700; sobre navy: blanco con texto `navy950` |
| Éxito | alto 54, radio 14 | `success`, texto blanco (marcar reto cumplido) |
| Oscuro compacto | alto 44, radio 12 | `navy900`, texto blanco 14/700 («Registrar avance») |
| Secundario | alto 48–52, radio 14 | blanco, borde 1.5 `borderStrong`, texto `ink` 15/600 |
| Sobre navy (CTA del coach) | alto 46, radio 12 | blanco, texto `navy900` |
| Estado deshabilitado | — | `opacity .5` (acciones) o relleno `disabledFill` (selección) |

### 4.3 Entradas de texto

Alto 48–54, radio 14 (burbuja de chat: radio 24), borde 1.5 `borderStrong`, relleno blanco, texto 16.
Etiqueta encima (14/600). **Variante sobre navy** (login): relleno `rgba(255,255,255,.08)`, borde
`rgba(255,255,255,.3)`, placeholder `#9FB4EE`, etiqueta `#E3EAFB`. Área de texto: 4 líneas, sin resize, radio 14.

### 4.4 Chips y píldoras

Radio 999, texto 12–13/700, padding `3–6 × 10–14`. Variantes: info (`blue100`/`blue800`), éxito, acento (XP),
aviso, neutro. Pastillas de etapa en el Camino: alto 40, borde 1.5, con icono de 14 (check / guion / candado).

### 4.5 Hoja inferior (bottom sheet)

Scrim `navy950` al 55 %; panel blanco, radio 26 arriba, `padding: 12 20 28`, manija 44×5 `borderStrong`;
`role=dialog`, cierre por scrim, botón «Cerrar»/«Cancelar» y gesto de arrastre. Usada en: detalle de reto
(Camino) y «Registrar avance» (Inicio). Flutter: `showModalBottomSheet` con `isScrollControlled: true` y
`useSafeArea: true`.

### 4.6 Tarjetas y listas

Tarjeta: blanco, borde 1 `border`, radio 16–20, padding 14–18. Listas dentro de una tarjeta con separadores
`divider` (1 px). Tarjeta oscura (`navy900`): radio 20–24, padding 18–20.

### 4.7 Barra de estado de conexión

Píldora de 44 dp de alto en la cabecera del Inicio (ver §6) y *banner* inferior a la cabecera con tres estados.
Misma lógica reutilizable en cualquier pantalla que escriba datos.

---

> **Estado:** Inicio (§6) y Camino (§7) están implementados y conectados al backend; la navegación inferior tiene por ahora **Inicio · Camino · Perfil** (Perfil = la pantalla «Cuenta»). Diferencias respecto al mockup: la píldora de red **refleja** el estado real (ya no es un botón de simulación); si el usuario aún no tiene emprendimiento, Inicio y Camino muestran «Registra tu emprendimiento» (el backend lo exige); el camino se dibuja para **N retos** (6 en la base actual), con curva y nodos calculados según el ancho; cumplir un reto requiere conexión; tras cumplirlo aparece un aviso si subes de nivel o ganas una insignia.
>
> **Implementado y conectado al backend:** login y registro (feature `auth`), más una pantalla `Splash` (restaurando sesión) y `Cuenta` (destino mínimo tras entrar). Los errores del servidor se muestran en un banner (`AuthErrorBanner`, fondo `accentTint`) y el correo repetido como error del campo.
> El registro no existía en el mockup: reutiliza el fondo navy
> y los campos del login (título «Crea tu cuenta.», nombre, correo, contraseña con mostrar/ocultar y confirmación).

## 5. Pantalla 1 — Ingreso (`features/auth`)

Fondo `navy950`, texto blanco, `padding: 72 28 32`, columna.

- **Decoración** (esquina superior izquierda, 420×420, `left:-10; top:-120`): dos órbitas (r 150 punteada blanca al 14 %
  con satélite `#FF5468`, giro 70 s; r 195 azul al 50 % con satélite blanco, giro inverso 110 s).
- **Bloque de marca**: logo 84×84 (radio 22, anillo `rgba(255,255,255,.2)`) con dos anillos *ripple* (rojo y blanco,
  2.8 s, desfasados 1.4 s) y entrada `popIn`. `h1` «Tu emprendimiento, acompañado.» + «Sigue tu progreso, conversa con tu
  coach de IA y agenda mentorías con el CIE-U.» (16 px `#C9D6F5`).
- **Formulario** (margen superior 36, gap 18): Correo electrónico (`tu@correo.com`, `username`) y Contraseña
  (`••••••••••`, `current-password`); botón blanco «Ingresar →» (alto 56, texto `navy950` 17/700); enlace
  «¿Olvidaste tu contraseña?» (alto ≥ 44).
- **Pie** (`margin-top: auto`, centrado): «¿Primera vez? **Regístrate**».
- Teclado: `TextInputAction.next` → `done`; `AutofillGroup`; el contenido debe desplazarse cuando aparece el teclado.
- Flujo real: `POST /api/v1/auth/login`; token en `flutter_secure_storage`; en éxito → `/home`.

---

## 6. Pantalla 2 — Inicio (`features/home`)

Contenido desplazable (`padding: 56 20 28`, gap 18) + barra inferior.

1. **Cabecera**: fecha («Miércoles 21 de octubre», 14 muted), `h1` «Hola, Camila» (Sora 26), emprendimiento
   («Sabores del Oriente», 14 muted). A la derecha, **píldora de red** (alto 44, 13/700): «En línea» (fondo
   `successTint`, texto `successDark`, punto `success`) / «Sin conexión» (fondo `warningTint`, texto `#5E3F00`, punto `warning`).
   Es un botón que, **en el mockup**, simula perder/recuperar red (en la app real refleja `connectivity` y no es tocable).
2. **Banner de conexión** (`role=status`, radio 14, padding `12 14`, 14/600), aparece con `bannerIn`:
   - Sincronizando: `blue50`/`blue800`, spinner 18 + «Sincronizando N registro(s)…».
   - Todo sincronizado: `successTint`/`successDark`, check + «Todo sincronizado.» (2.4 s).
   - Sin conexión: `warningTint`/`#5E3F00`, icono nube tachada + «Sin conexión. Tus registros se guardan en este
     dispositivo y se sincronizarán después.» (+ « Pendientes: N.»).
3. **Progreso** (tarjeta `navy900`, radio 24, padding 20): anillo de 104 dp (pista `rgba(255,255,255,.16)`, trazo 9
   `blueRing`, redondeado, inicia a las 12 en punto) con **295** (Sora 26) y «XP» (12/700, .06em) centrados; a la
   derecha «Nivel 2» (Sora 20), «Te faltan 105 XP para el nivel 3.» y chip «Etapa: Incubación». Relleno del anillo = 295/400 = 73.75 %.
4. **Siguiente reto** (tarjeta blanca radio 20): overline «SIGUIENTE RETO», chip «+150 XP», título
   «Construir un prototipo mínimo» (Sora 18/600) y botón primario «Ver en mi camino →» → `/journey`.
5. **Compromisos pendientes** (`h2` + «N por hacer»): tarjeta con filas de checkbox (área 48×56; caja 28, radio 9,
   borde 2 `outlineOff` → `success` al marcar con check animado). Texto 15/600 (tachado y `muted` al cumplir) y
   fecha («Vence el jueves 22», 13 muted). Si se marca sin conexión aparece chip «Pendiente de sincronizar» (`warningTint`, `pop`).
   Datos: «Enviar guion de entrevista a la mentora», «Actualizar costos del prototipo», «Subir fotos del prototipo».
6. **Mis avances**: `h2` + botón oscuro «＋ Registrar avance». Cada avance = tarjeta (radio 16) con texto, fecha
   («Ayer», «Ahora») y chip «Sincronizado» (éxito) / «Pendiente de sincronizar» (aviso). El nuevo entra con
   `fadeUp` + `flash`.
7. **Hoja «Registrar avance»**: título, etiqueta «¿Qué avanzaste?», área de texto (placeholder «Describe tu avance o
   hito alcanzado»), pista (en línea: «Se guardará en el historial de tu emprendimiento.»; sin conexión: «Sin conexión: se
   guardará en tu dispositivo y se enviará al volver la red.»), botones «Cancelar» y «Guardar» (`opacity .5` si vacío).

**Reglas de sincronización (a respetar en la implementación real)**: escritura local primero
(`data/datasources/*_local_data_source.dart`), cola de pendientes, reintento al volver la red, el banner cuenta
los pendientes y los chips cambian a «Sincronizado» al confirmar el servidor. Marcar compromisos y registrar
avances deben funcionar sin red.

---

## 7. Pantalla 3 — Camino gamificado (`features/journey`)

Columna a pantalla completa: cabecera fija, camino desplazable, barra inferior.

- **Cabecera** (`padding: 56 20 12`): `h1` «Mi camino» + píldora `navy900` «⚡ 295 XP» (rayo `#FF8A9A`).
  Debajo, fila horizontal desplazable de **pastillas de etapa**: Preincubación (cumplida, verde + check),
  Incubación (en curso, azul + guion), Crecimiento y Graduación (bloqueadas, blanco con borde + candado).
  Leyenda 12/600: «Camino verde: cumplido» (círculo verde con check) · «Camino azul: en curso» (círculo azul).
- **Camino** (lienzo 390×590 desplazable): curva Bézier que une 5 nodos, en zigzag (x alternando izquierda/derecha):

| # | Reto | XP | Etapa | Posición (x, y) |
|---|---|---|---|---|
| 1 | Definir la propuesta de valor | 100 | Preincubación | 100, 60 |
| 2 | Entrevistar a 5 clientes potenciales | 120 | Preincubación | 260, 170 |
| 3 | Construir un prototipo mínimo | 150 | Incubación | 120, 280 |
| 4 | Registrar ventas de prueba | 200 | Incubación | 270, 390 |
| 5 | Presentar el plan financiero | 250 | Crecimiento | 160, 500 |

  - Tramo base: trazo punteado `blueTrack` de 8 dp (puntos redondos). Tramo recorrido: trazo continuo `success` de 9 dp
    que se dibuja con animación hasta el último nodo cumplido (`fracción = (cumplidos − 1) / 4`).
  - **Nodo** (círculo 64): *cumplido* = fondo `success`, icono check blanco; *en curso* = fondo `primary`, icono bandera
    blanca y anillo *ripple* continuo; *bloqueado* = fondo `neutralFill`, borde 2 `borderStrong`, candado `muted`. Hover/pulsación: escala 1.08/.95.
  - **Etiqueta** junto al nodo (ancho 128, hacia el lado con más espacio): título (Sora 14/600) + estado
    («Cumplido · +100 XP» `successDark`, «En curso · +150 XP» `blue800`, «Bloqueado» `muted`).
  - `aria-label` del nodo: «Reto 3: {título}, en curso».
- **Hoja de detalle** (al tocar un nodo): chips de estado y «+N XP» (acento), título (Sora 22), «Etapa: …», descripción,
  y según estado: botón verde **«Marcar como cumplido»** (en curso) · aviso gris con candado «Completa el reto anterior para
  desbloquearlo.» (bloqueado) · aviso verde «Reto cumplido. La recompensa ya está en tu perfil.» (cumplido) · «Cerrar».
- **Al cumplir**: se cierra la hoja, el siguiente nodo pasa a «en curso», el camino verde se prolonga, el contador de XP
  suma y aparece la burbuja flotante verde «+N XP» (Sora 20, `role=status`).
- Descripciones de los retos: (1) «Describe en una frase qué problema resuelves y para quién.» (2) «Conversa con clientes
  reales y registra lo que aprendiste de cada conversación.» (3) «Crea la versión más simple de tu producto o servicio para
  ponerla a prueba con clientes.» (4) «Realiza tus primeras ventas y anota los resultados y aprendizajes.» (5) «Estructura
  costos, precios y punto de equilibrio con apoyo de un mentor.»
- Regla de negocio: el XP de un reto se concede **una sola vez**; los retos se desbloquean en orden.
- Implementación: el camino se dibuja con `CustomPainter` (Path con `cubicTo` + `PathMetric` para el punteado y la animación
  de trazo); los nodos son `Positioned` sobre un `Stack`.

---

## 8. Pantalla 4 — Coach IA (`features/coach`)

- **Cabecera blanca** (borde inferior): avatar 46 `navy900` con icono de destellos (sparkles) y punto verde de «en línea» con
  halo pulsante; «Coach CIE-U» (Sora 20) y «Asistente de IA · orientación inicial». Debajo, **aviso permanente**
  (`warningTint2`, texto `#5E3F00`, 13 px, icono info): «La IA no sustituye a un asesor o mentor especializado.»
- **Temas sugeridos** (chips horizontales de 44, borde 1.5): Modelo de negocio · Marketing · Ventas · Costos ·
  Financiamiento. Al tocar uno se envía su pregunta (p. ej. «¿Cómo valido mi modelo de negocio?»).
- **Mensajes** (lista invertida, `column-reverse`, padding `12 20`, gap 12; los nuevos entran con `bubbleIn`):
  - Usuario: burbuja `primary`, texto blanco 15, radio `20 20 6 20`, máx. 80 %, alineada a la derecha.
  - Coach: burbuja blanca con borde `border`, radio `20 20 20 6`, máx. 86 %. Debajo, si hay fuente, chip `blue50`
    «📄 Fuente: base documental del CIE-U» (icono documento, sin emoji real) y, si procede, **tarjeta de derivación**
    (`navy900`, radio 16): «¿Prefieres hablar con una persona? Puedo derivar tu consulta a un mentor.» + botón blanco
    «Solicitar mentoría →» → `/mentoring`.
  - «Escribiendo»: burbuja con tres puntos que rebotan (1.5 s de latencia simulada).
  - Saludo inicial: «Hola, Camila. Soy tu coach virtual. Puedo orientarte en modelo de negocio, marketing, ventas, costos y
    financiamiento. ¿Con qué empezamos?»
- **Respuesta sin base** (fallback): «No encontré información suficiente en la base documental del CIE-U para responder con
  certeza.» — sin chip de fuente y **con** tarjeta de derivación. Financiamiento también deriva.
- **Entrada** (blanco, borde superior): campo en píldora (alto 48, fondo `bg`, placeholder «Escribe tu consulta») + botón
  circular 48 `primary` con icono enviar (`opacity .5` si vacío o si el coach está escribiendo). Mientras escribe no se
  puede enviar otro mensaje.
- Backend: el motor es RAG (Ollama) sobre `documentos_conocimiento` / `fragmentos_documento`; los mensajes se
  guardan en `conversaciones_ia` / `mensajes_ia`. La UI debe distinguir siempre «respuesta con fuente» de «sin fuente».
  El mockup empareja temas por palabras clave (costo/precio, venta, market/publicidad, financ/crédito/inversión,
  modelo/cliente); es solo una simulación.

---

## 9. Pantalla 5 — Mentorías (`features/mentoring`)

- **Cabecera**: `h1` «Mentorías» y control segmentado de dos opciones (contenedor `neutralFill`, radio 16, padding 4;
  segmento activo `navy900` texto blanco, inactivo transparente `ink2`, alto 44, radio 12): **Agendar** · **Mis sesiones**.
- **Agendar** (`padding: 6 20 0`, gap 20):
  1. Aviso verde: «Tu avance en Incubación habilitó el agendamiento.» (agendar se habilita por haber alcanzado la etapa).
  2. **Elige un mentor** (tarjetas-botón alto ≥ 72, radio 18, borde 2): avatar 48 con iniciales, nombre (16/700), especialidad (13 muted)
     y círculo de selección 24 (relleno `primary` + check). Seleccionado = borde `primary` + fondo `blue50`.
     Mentores: *Marcelo Cuéllar* — Ventas y marketing · *Daniela Paz* — Finanzas y costos · *Andrés Rivero* —
     «Financiamiento · se desbloquea al completar «Construir un prototipo mínimo»» (bloqueado: fondo `disabledFill`,
     candado, `cursor not-allowed`/deshabilitado).
  3. **Fecha**: carrusel horizontal de tarjetas 64×72 (radio 16, borde 2): día abreviado (13) + número (Sora 22/700);
     seleccionado = fondo `primary`, texto blanco. Días: Jue 22, Vie 23, Lun 26, Mar 27, Mié 28 (octubre).
  4. **Horario disponible**: rejilla de 3 columnas, botones alto 52 (radio 14, borde 2): 09:00 · 10:30 · 14:00 · 15:30 · 17:00.
     Seleccionado = `primary`; **reservado** = fondo `disabledFill`, texto tachado `muted`, deshabilitado, `aria-label`
     «{hora}, reservado». Leyenda: «Los horarios tachados ya están reservados.» Cambiar de mentor o de día reinicia el horario.
  5. **Barra fija inferior** (sticky, borde superior): resumen («Selecciona un horario para continuar.» o
     «Marcelo Cuéllar · Jue 22 de octubre · 09:00») y botón primario **«Confirmar mentoría»** (alto 54, `opacity .5` sin horario).
- **Éxito**: círculo verde 96 con *ripple* (2 repeticiones) y check que se dibuja (0.6 s), «Mentoría agendada» (Sora 24),
  «Tu mentor y tú podrán ver la sesión programada.», tarjeta «DETALLE» (mentor + fecha/hora) y botones «Ver mis sesiones» (primario)
  / «Agendar otra» (secundario). El horario reservado queda ocupado.
- **Mis sesiones**: **Próximas** — vacío con borde discontinuo «Aún no tienes sesiones programadas.» o tarjetas con calendario
  navy 52×56 (día + número), mentor (16/700) y «hora · especialidad». **Realizadas** — tarjeta con mentor, chip «Registrada»
  (éxito), «Hace 1 semana · Ventas y marketing» y chips «2 recomendaciones» (info) y «1 compromiso» (aviso).
- Backend: `sesiones_acompanamiento`, `sesion_participantes`, `asignaciones`, `recomendaciones`, `compromisos`.
  El desbloqueo del mentor 3 depende del reto «Construir un prototipo mínimo» (relación con `gamification`/`ventures`).

---

## 10. Pantalla 6 — Perfil y logros (`features/profile`)

Contenido desplazable (`padding: 56 20 28`, gap 22).

1. **Identidad**: avatar 76 (círculo `navy900` con iniciales «CJ» Sora 20/700, rodeado de un aro punteado azul de 2 con
   satélite `#D61F3A` que gira 14 s); «Camila Justiniano» (Sora 22), «Sabores del Oriente» (14 muted), chips «Incubación»
   (`blue100`/`blue900`) y «Nivel 2» (`accentTint`/`accentOn`).
2. **XP** (tarjeta `navy900`, radio 20, padding 18): «295 XP» (Sora 26 + 14), «Meta nivel 3: 400 XP», barra de 12 dp
   (pista `rgba(255,255,255,.16)`, relleno `#7FA6FF` al 73.75 %, anima 1.2 s).
3. **Mis insignias** («1 de 6»): rejilla de 3 columnas (gap 12). Tarjeta blanca radio 18, icono 56 (radio 16), nombre
   (12/700) y estado (11/600).
   - Obtenida: fondo `accent` `#D61F3A`, icono medalla blanco, brillo animado, estado «Obtenida».
   - Bloqueada: fondo `neutralFill`, candado `muted`, estado «Bloqueada».
   - Insignias: **Primer paso** (obtenida), Constancia, Validador, Bitácora al día, Conector, Graduado.
4. **Historial de XP**: tarjeta con filas (texto 15/600 + «Hace N días») y chip verde «+N XP»:
   Insignia «Primer paso» +25 (hace 2 días) · Reto: Entrevistar a 5 clientes potenciales +120 (hace 6 días) ·
   Reto: Definir la propuesta de valor +100 (hace 2 semanas) · Reto: Completar el perfil del emprendimiento +50 (hace 3 semanas).
5. **Sincronización**: tarjeta con icono nube-check verde, «Datos sincronizados» y «No hay registros pendientes en este
   dispositivo.» (debe mostrar el conteo real de pendientes cuando los haya).
6. **Cerrar sesión**: botón secundario (icono log-out) → borra el token de `flutter_secure_storage` y vuelve a `/login`.

Backend: `emprendedor_insignias`, `movimientos_xp`, `insignias`; nivel y metas se derivan del XP acumulado
(regla de niveles pendiente de definir: el mockup usa nivel 2 → meta 400 XP).

---

## 11. Datos de dominio usados por el diseño

| Concepto en UI | Origen (módulo → tablas) |
|---|---|
| Sesión, usuario, rol | `users` → `usuario`, `rol` |
| Emprendedor y emprendimiento (nombre, etapa) | `entrepreneurs` → `emprendedor`; `ventures` → `emprendimiento`, `etapas`, `emprendimiento_etapas` |
| Retos, camino, XP, insignias | `gamification` → `retos`, `emprendimiento_retos`, `movimientos_xp`, `insignias`, `emprendedor_insignias` |
| Compromisos y avances | `mentoring` → `compromisos`, `seguimientos`; `ventures` → `hito` |
| Mentorías y recomendaciones | `mentoring` → `sesiones_acompanamiento`, `sesion_participantes`, `asignaciones`, `recomendaciones` |
| Coach IA | `ai_assistant` → `conversaciones_ia`, `mensajes_ia`, `documentos_conocimiento`, `fragmentos_documento` |

IDs: `int` (BIGINT, global §5); fechas ISO-8601 UTC convertidas a formato local en la capa de presentación
(«Miércoles 21 de octubre», «Hace 2 días»). Los DTO mantienen los nombres en español del esquema (global §4.9).

---

## 12. Mapeo a la arquitectura feature-first por capas

Estructura objetivo (regla móvil §3; `presentation` → `domain` ← `data`):

```
lib/
├── app/
│   ├── app.dart                 MaterialApp.router
│   ├── router.dart              StatefulShellRoute con las 5 pestañas + /login
│   └── theme/                   app_colors.dart · app_text.dart · app_spacing.dart · app_theme.dart
├── core/
│   ├── network/                 Dio + interceptor Bearer
│   ├── storage/                 secure storage (token) y caché/cola offline
│   ├── connectivity/            *propuesta* (estado de red) — requiere aprobación (regla 4)
│   └── error/                   Failure
├── features/
│   ├── auth/                    pantalla 1
│   ├── home/ (o ventures)       pantalla 2: compromisos, avances, resumen  ← ver nota
│   ├── journey/ (gamification)  pantalla 3 y logros de la 6
│   ├── coach/ (ai_assistant)    pantalla 4
│   ├── mentoring/               pantalla 5
│   └── profile/ (users)         pantalla 6
└── shared/widgets/              AppBottomNav, SheetScaffold, StatusPill, XpChip, PrimaryButton…
```

**Nota de nombres (regla global §4.6)**: el nombre de la feature debe coincidir con el módulo del backend.
`AGENTS.md` solo prevé `auth`, `users`, `projects`, `mentoring`, `events`. Este diseño necesita además
`gamification` (camino, XP, insignias), `ai_assistant` (coach) y probablemente `ventures`/`entrepreneurs` (inicio).
Los nombres entre paréntesis arriba son la alineación correcta; hay que **proponerlos al usuario, registrarlos
en la tabla de features de `AGENTS.md` y mantener el mismo nombre en la web** en el mismo commit en que se creen.
El Inicio es una pantalla de *composición*: lee de varias features por sus APIs públicas (`index.dart`), no importa
archivos internos.

Reglas que este diseño pone a prueba:

- **Estado**: Riverpod (`flutter_riverpod`) para todo: sesión, red, cola offline, chat, selección de mentor/fecha/hora,
  XP. Sin singletons.
- **Navegación**: `go_router`; cada feature exporta su lista de rutas; las hojas inferiores son `showModalBottomSheet`,
  no rutas.
- **Dominio puro**: reglas como «los retos se desbloquean en orden», «el XP se concede una vez», «agendar exige haber
  alcanzado la etapa» viven en casos de uso (`CompleteChallenge`, `BookSession`), no en widgets.
- **Offline**: los casos de uso `ToggleCommitment` y `LogProgress` escriben primero en local y encolan; un
  `SyncService` en `core/` vacía la cola al recuperar red (la capa `data` devuelve `Failure`, nunca excepciones de red).
- **DTO ≠ entidad**: `freezed` + `json_serializable` en `data/models/`; las entidades de `domain/` no tienen `fromJson`.
- **Tests**: `domain` y repositorios con test unitario; pantallas con widget test (estados offline, hoja de reto,
  chat con y sin fuente, horario reservado). `flutter analyze` y `flutter test` deben pasar.

> Aclaración sobre el estado: `pubspec.yaml` ya declara `flutter_riverpod`, `go_router`, `dio`,
> `flutter_secure_storage`, `freezed_annotation`, `json_annotation`, `build_runner`, `freezed`, `json_serializable`
> y `mocktail`; el `AGENTS.md` aún los lista como «no instalado». Conviene corregir esa tabla.

---

## 13. Accesibilidad (checklist del diseño)

- [ ] Todo control táctil ≥ 44×44 dp (`minimumSize` en botones; `Semantics` en iconos).
- [ ] Contraste ≥ 4.5:1 con las parejas definidas (no usar texto `muted` sobre `neutralFill` pequeño sin verificar).
- [ ] Estados nunca solo por color: «Cumplido / En curso / Bloqueado», «Obtenida / Bloqueada», «reservado» tachado.
- [ ] `Semantics` con etiquetas completas: nodo «Reto 3: …, en curso»; horario «09:00, reservado»; checkbox «Marcar
      como cumplido: …»; botón de red con la acción que ejecuta.
- [ ] Banners y burbuja de XP con `liveRegion` (equivale a `role="status"`).
- [ ] Hojas modales atrapan el foco y se cierran con atrás del sistema.
- [ ] Orden de lectura lógico; la ilustración (órbitas, brillos) está excluida del árbol semántico.
- [ ] Respetar `textScaler` hasta 1.3 y `disableAnimations`.
- [ ] Teclado del chat no tapa el campo de entrada (`resizeToAvoidBottomInset`).

---

## 14. Activos y pendientes

- **Logo del CIE-U**: ya en `assets/images/cie_u_logo.png` (84×84 en el login, radio 22).
- **Fuentes Sora y DM Sans**: vía `google_fonts` (ver §3.2).
- **Iconos**: el mockup usa trazos tipo Feather. Con Material Icons (`uses-material-design: true`) elegir los
  equivalentes más cercanos (`home_outlined`, `flag_outlined`, `chat_bubble_outline`, `calendar_today_outlined`,
  `person_outline`, `lock_outline`, `check`, `bolt`, `auto_awesome`, `send`, `logout`, `cloud_done_outlined`,
  `cloud_off_outlined`) o añadir `lucide_icons_flutter` (dependencia nueva: consultar antes).
- Los datos del mockup (Camila Justiniano, Sabores del Oriente, mentores, fechas de octubre) son **ficticios**.
- Lo no diseñado y que hay que decidir con el usuario: registro («Regístrate»), recuperación de contraseña, estados
  de carga/vacío/error de red por pantalla, pantalla de mentor bloqueado (qué hace al tocarlo), cancelar o reprogramar una
  sesión, notificaciones push, modo oscuro, tablet/landscape, reglas de niveles de XP.
