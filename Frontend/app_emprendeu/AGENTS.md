# App móvil EmprendeU — Arquitectura feature-first por capas

> Lee antes `../../AGENTS.md` (reglas globales del monorepo).
> Este documento es **prescriptivo**: define cómo debe quedar la app móvil.

---

## 1. Stack

| Pieza | Elección | Estado |
|---|---|---|
| SDK | Flutter, Dart `^3.13.5` (`pubspec.yaml`) | instalado |
| Lints | `flutter_lints` ^6.0.0 (`analysis_options.yaml`) | instalado |
| Iconos | `cupertino_icons` | instalado |
| Plataformas generadas | android, ios, web, linux, macos, windows | **Objetivo real: android + ios.** No escribas código específico de escritorio/web sin pedirlo. |

### Stack designado (ya declarado en `pubspec.yaml`)

Los paquetes están instalados y en uso: `flutter_riverpod`, `go_router`, `dio`,
`flutter_secure_storage`, `freezed` + `json_serializable` + `build_runner`,
`google_fonts`, `shared_preferences`, `connectivity_plus` y `mocktail`. Estado real:
`lib/` tiene `app/` (tema, router con barra inferior, `providers.dart`), `core/`
(config, error, network, storage, connectivity, utils), `shared/widgets/` y cuatro
features **conectadas al backend**: `auth` (login, registro, sesión), `ventures`
(registrar y ver el emprendimiento), `gamification` (**Camino** y XP) y `mentoring`
(compromisos y avances **con soporte sin conexión**, y **agendar mentorías**), más `home` (la pantalla de
**Inicio**, que solo compone las anteriores). Las decisiones quedan fijadas aquí:

| Necesidad | Paquete designado | Alternativa descartada |
|---|---|---|
| Estado + inyección | **`flutter_riverpod`** | Bloc, Provider |
| Navegación | **`go_router`** | Navigator 1.0 a mano |
| HTTP | **`dio`** | `http` |
| Modelos / serialización | **`freezed`** + `json_serializable` + `build_runner` (dev) | clases a mano |
| Almacenamiento seguro (token) | **`flutter_secure_storage`** | `shared_preferences` para el token |
| Tests | `flutter_test` + `mocktail` (dev) | |
| Tipografía (Sora, DM Sans) | **`google_fonts`** | empaquetar las fuentes a mano |
| Cola/cachés locales (no secretos) | **`shared_preferences`** (detrás de `KeyValueStore`) | SQLite/Isar (excesivo para una cola pequeña) |
| Estado de red | **`connectivity_plus`** (detrás de `ConnectivitySource`) | sondeo manual |
| Elegir un archivo (evidencia) | **`file_picker`** (detrás de `EvidencePicker`, en `documents`) | pedir permisos de galería a mano |
| Leer PDF en el celular (archivos propios para la IA) | **`read_pdf_text` 0.3.1** (PDFBox en Android, PDFKit en iOS; detrás de `TextExtractor`) | `pdfrx`: su hook nativo exige `clang` en la máquina y rompía `flutter test`; `syncfusion_flutter_pdf`: licencia comercial |
| Leer DOCX / rutas de archivos | **`archive`** + **`xml`** (el `.docx` es un ZIP con XML) y **`path_provider`** | |
| Abrir un documento descargado (CU30) | **`open_filex` 5.0.0** (detrás de `FileOpener`, en `documents`). Sus permisos `READ_MEDIA_*` y `READ_EXTERNAL_STORAGE` se quitan en `AndroidManifest.xml` (`tools:node="remove"`): solo abre archivos privados de la app | |
| Notificaciones push | **`firebase_core` + `firebase_messaging`** (FCM, detrás de `PushMessaging`, en `notifications`). Se configura con `android/app/google-services.json`: el plugin `com.google.gms.google-services` solo se aplica si el archivo existe, así que sin él la app compila y usa solo la bandeja | `flutter_local_notifications` (el push con la app abierta se muestra como `SnackBar`) |
| IA en el celular (chat + embeddings) | **`flutter_edge_ai` 2.5.4 + `flutter_edge_ai_litertlm` 1.19.0**, versiones exactas (motor LiteRT-LM, detrás de `LocalAiRepository`, en `ai_assistant`) | `llama_cpp_dart` (sin mantenimiento activo); embeddings GGUF (el paquete aún no los ejecuta) |

> **IA local: requisitos de plataforma.** LiteRT-LM exige `minSdk 30` (Android 11) y solo corre en
> **arm64**: por eso `android/app/build.gradle.kts` fija `minSdk = 30` para toda la app. En un emulador
> x86_64 la tarjeta muestra «no compatible» y el Coach sigue con el servidor. **iOS aún no:** el paquete
> pide un `ios/Podfile` con `use_frameworks! :linkage => :static` y el proyecto usa Swift Package Manager
> (sin Podfile); `LocalAiEngineDataSource.isSupported` devuelve `false` fuera de Android.

> Si el equipo prefiere **Bloc** en vez de Riverpod, hay que cambiarlo **en este
> documento primero** y luego escribir código. No se mezclan dos gestores de estado.

Para reproducirlos en un proyecto limpio:

```bash
flutter pub add flutter_riverpod go_router dio flutter_secure_storage freezed_annotation json_annotation
flutter pub add --dev build_runner freezed json_serializable mocktail
```

> **Diseño visual:** colores, tipografía, pantallas y componentes están en
> [`design.md`](design.md). Léelo antes de escribir cualquier UI.

## 2. Qué significa "feature-first por capas" aquí

Primero se divide por **feature** (dominio de producto), y dentro de cada feature
por **capas** (`data` / `domain` / `presentation`). Las dependencias apuntan hacia
adentro: la UI depende del dominio, el dominio no depende de nada externo.

```
presentation  ──►  domain  ◄──  data
```

## 3. Estructura de carpetas

```
lib/
├── main.dart                 # solo: bootstrap + runApp(ProviderScope(child: App()))
├── app/
│   ├── app.dart              # MaterialApp.router
│   ├── router.dart           # go_router: rutas de cada feature + barra inferior (StatefulShellRoute)
│   ├── providers.dart        # raíz de composición: une las implementaciones `data` de cada feature
│   └── theme/                # ThemeData completo (AppBar, botones, inputs, chips, tarjetas, hojas, diálogos),
│                             # app_colors.dart y app_tokens.dart (AppSpacing, AppRadii, AppMotion)
├── core/
│   ├── config/               # env, base url, flavors
│   ├── network/              # cliente Dio, AuthInterceptor, eventos de sesión, mapeo de errores
│   ├── error/                # Failure, Result
│   ├── storage/              # token seguro, KeyValueStore (cola/cachés), userFilesDirectory, LocalDataCleaner
│   ├── connectivity/         # estado de red (connectivity_plus detrás de ConnectivitySource)
│   └── utils/                # formato de fechas, referencia de cliente
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/  # <f>_remote_data_source.dart, <f>_local_data_source.dart
│       │   ├── models/       # DTO (freezed + json_serializable) ↔ JSON del backend
│       │   └── repositories/ # implementación del contrato de domain
│       ├── domain/
│       │   ├── entities/     # objetos de negocio puros (sin JSON, sin Flutter)
│       │   ├── repositories/ # interfaces (contratos)
│       │   └── usecases/     # un caso de uso = una operación de negocio
│       └── presentation/
│           ├── screens/      # pantallas (una por ruta)
│           ├── widgets/      # widgets propios de la feature
│           └── controllers/  # notifiers/providers de Riverpod + estado de la pantalla
└── shared/
    └── widgets/              # AppShell y AppBottomNav; motion.dart (FadeUp, PopIn, RippleBurst, TypingDots,
                              # Skeleton) y state_views.dart (ErrorState, EmptyState)
test/                         # espejo exacto de lib/
```

### Features previstas (mapa inicial — ajústalo con el usuario antes de implementar)

`auth` ✅, `ventures` ✅ (editar, hitos), `gamification` ✅ (Camino, XP e insignias), `mentoring` ✅ (compromisos y avances, agendar y ver sesiones, historial),
`documents` ✅ (evidencia de hitos), `ai_assistant` ✅ (Coach IA y conversaciones anteriores), `needs` ✅ (necesidades y dificultades), `training` ✅ (capacitaciones), `notifications` ✅ (bandeja de avisos y push), `home` ✅ — los mismos nombres que los módulos del backend y que las features de la web
(regla global §4.6).

> **`home` es una excepción documentada a la regla 6:** no tiene módulo en el backend porque
> es una pantalla de **composición** (Inicio). No tiene `data` ni `domain`: solo `presentation`,
> y lee de las demás features únicamente por su `index.dart`. No añadas lógica de negocio ahí.

## 4. Orden de construcción (primeros pasos)

1. Hecho: `main.dart` solo arranca la app.
2. Hecho: `core/config`, `core/network`, `core/error`, `core/storage`.
3. Hecho: `app/app.dart`, `app/router.dart`, `app/theme/`, `app/providers.dart`.
4. Hecho: `auth` completa; es la **plantilla de las demás** (ver «Cómo se conecta una feature»).
5. Hecho: `ventures`, `gamification`, `mentoring` (con cola offline) y `home`.
6. Hecho: `ai_assistant` (Coach IA) y Perfil completo; al sumar cada pestaña, se añade a `AppShell`.

### Cómo se conecta una feature (patrón de `auth`)

1. `domain/` (Dart puro): entidades, `repositories/<f>_repository.dart` (interfaz) y casos
   de uso que devuelven `Result<T>` (`core/error/result.dart`).
2. `data/`: DTO `freezed` + `json_serializable`, `datasources/` (Dio / almacenamiento) y
   `repositories/..._impl.dart`, que captura `DioException` y la convierte en `Failure`
   con `mapDioException` (`core/network/api_error_mapper.dart`).
3. `data/<f>_data_providers.dart` exporta los `Override` que enlazan la interfaz con su
   implementación; `app/providers.dart` los reúne y `main.dart` los pasa al `ProviderScope`.
   Así `presentation` solo conoce `domain`.
4. `presentation/controllers/`: `AsyncNotifier` que llama a los casos de uso. Las pantallas
   muestran el `Failure.message`; nunca ven una excepción de red.
5. Tests: casos de uso y mapeo con `FakeRepository`; pantallas con
   `authRepositoryProvider.overrideWithValue(fake)`.

### Navegación y estructura de pantallas

- `app/router.dart` monta `StatefulShellRoute.indexedStack` con la barra inferior
  (`shared/widgets/app_shell.dart`, `app_bottom_nav.dart`): **Inicio · Camino · Mentorías · Coach · Perfil**. Cada
  feature exporta su lista de rutas (`homeRoutes`, `gamificationRoutes`, `mentoringRoutes`, `accountRoutes`).
  La pestaña **Coach** (`assistantRoutes`) va entre Mentorías y Perfil.
- Tras iniciar sesión se va a `/home`; sin sesión, a `/login`. El `redirect` reacciona a
  `authControllerProvider`.
- **Riverpod no reintenta solo:** `ProviderScope(retry: (_, _) => null)`. Los errores se
  muestran con «Reintentar» (los reintentos automáticos de Riverpod 3 dejaban la pantalla en
  «cargando»).
- Las pantallas con scroll tienen *pull to refresh* y las listas `AsyncValue` muestran
  cargando / error con `Failure.message` / vacío.

### Tema, movimiento y estados

- **El tema manda.** `AppTheme` estiliza todos los componentes de Material: un `OutlinedButton`, un chip o un
  `TextField` sin estilo propio ya salen con la marca. No copies `styleFrom` ni `OutlineInputBorder` en las pantallas;
  solo se sobrescribe lo que de verdad difiere (campos sobre navy, la burbuja del Coach).
- **Movimiento** (`shared/widgets/motion.dart`, duraciones y curvas en `AppMotion`): todo respeta
  `MediaQuery.disableAnimations`. `FadeUp` es para lo que **llega** (un resultado, un banner), no para cada fila de
  una lista. Las animaciones de entrada son finitas y sin `Timer` (los retrasos van en un `Interval`).
- **Celebración**: subir de nivel o ganar una insignia abre `showCelebration` (`gamification`), a pantalla completa y
  con háptica; agendar una mentoría termina en una pantalla de confirmación. Un `SnackBar` queda para avisos menores.
- **Errores y vacíos**: `ErrorState` y `EmptyState` (`shared/widgets/state_views.dart`). No se arma otro
  «texto + Reintentar» a mano.
- **Cambio de pestaña** con un fundido corto en `AppShell` (no remonta las ramas) y háptica en la barra inferior.

### Sin conexión (cola y sincronización)

- Un **compromiso marcado** y un **avance registrado** sin red se guardan en el dispositivo
  (`mentoring/data/datasources/mentoring_local_data_source.dart`, bajo el prefijo `user.`) y
  se ven con la etiqueta «Pendiente de sincronizar». El último cambio de un mismo compromiso
  reemplaza al anterior.
- Cada avance lleva un `referencia_cliente` (aleatorio, `core/utils/client_ref.dart`): el backend
  no lo duplica si se reenvía.
- `SyncController` (en `mentoring`) envía todo en un lote (`POST /mentoring/sync`) al volver la
  red (`onlineProvider`, que combina `connectivity_plus` con lo que ve la app) y reintenta cada 30 s
  mientras haya pendientes. Lo que el servidor rechaza se descarta y se informa; si falla por red,
  la cola se conserva.
- **Cumplir un reto del Camino exige conexión** (el servidor valida orden y XP).
- Al cerrar sesión (o ante un 401) se borra todo lo guardado bajo `user.` (`LocalDataCleaner`)
  para que otra cuenta no vea esos datos. Lo pendiente sin enviar se pierde en ese caso.
- `AuthInterceptor` (`core/network`) añade el Bearer y emite un evento de sesión vencida ante un 401.

### Conexión con el backend

- **URL del API:** `--dart-define=API_BASE_URL=...` (`core/config/app_config.dart`). Por
  defecto `http://10.0.2.2:8000/api/v1` (emulador Android → máquina anfitriona). En el
  simulador de iOS usa `http://127.0.0.1:8000/api/v1`; en un teléfono real, la IP de tu PC.
- **HTTP en desarrollo:** el manifiesto *debug* de Android permite tráfico http y
  `Info.plist` permite red local en iOS. En producción el API debe ir por **HTTPS**.
- **Sesión:** el JWT se guarda con `flutter_secure_storage`. Esta app es solo para el rol
  `emprendedor`: una cuenta de personal se rechaza (`WrongPlatformFailure`) y su token no
  se guarda. El registro (`POST /auth/register`) crea un emprendedor y entra con él.
- **Agendar y ver mentorías** (CU10, CU23; requiere conexión): `mentoring` tiene un segundo repositorio,
  `BookingRepository`, aparte del de la cola sin conexión. La pestaña «Mentorías» lista las sesiones
  (`GET /mentoring/sessions/me`) con chips de estado y un periodo (`showDateRangePicker`); «Agendar
  mentoría» queda desactivado con el motivo si la etapa aún no lo permite (`booking-status`). El flujo
  `/mentoring/book` es asesor asignado → día (14 días) → turno libre → tema opcional → confirmar. El caso
  de uso `BookSessionUseCase` **vuelve a pedir los turnos del día antes de agendar**: si el horario se
  ocupó, devuelve `SlotUnavailableFailure`, la pantalla avisa y renueva la lista. El emprendedor solo ve
  asesores asignados y habilitados (lo filtra el backend).
- **Detalle y cancelar mentoría** (CU23, requiere conexión): tocar una tarjeta de la lista abre `/mentoring/session/:id`
  (`GET /mentoring/sessions/{id}`). Una mentoría **programada** se cancela con confirmación (`POST /sessions/{id}/cancel`,
  `CancelSessionUseCase`) y libera el horario; si el servidor responde `session_closed` (ya realizada o cancelada) llega
  como `SessionClosedFailure` y la pantalla se refresca.
- **Historial del emprendimiento** (CU19, requiere conexión): botón «Ver historial del emprendimiento» en
  Mentorías → `/mentoring/history`, que llama a `GET /mentoring/ventures/me/history` (`GetHistoryUseCase`,
  `HistoryEvent`). Se filtra por **orden, tipos de evento (varios) y periodo** con un `HistoryFilter` (igualdad por valor:
  es la clave del provider). Los tipos viajan como `tipo=a&tipo=b` (`ListFormat.multi`; el formato por defecto de Dio,
  `tipo[]=a`, no lo lee FastAPI).
- **Tareas y compromisos** (CU22, requiere conexión): botón «Tareas y compromisos» en Mentorías → `/mentoring/tasks`,
  que llama a `GET /mentoring/tasks/me` (`GetTasksUseCase`, `Task`, `TaskFilter`): compromisos e hitos con chips de
  estado (pendientes/cumplidas), tipo y rango de fecha prevista; las vencidas llevan su etiqueta. Es una consulta: la cola
  sin conexión de compromisos de `CommitmentsSection` no cambia.
- **Coach IA** (CU11, requiere conexión): la pestaña «Coach» (`/coach`) abre la conversación más reciente
  (`GET /ai/conversations/me` y sus mensajes) o una invitación con preguntas sugeridas. `AskCoachUseCase` valida el texto
  (no vacío, máximo 2000) y `POST /ai/chat` lleva **plazo propio de 90 s** (el modelo local tarda más que una consulta
  normal). Cada respuesta muestra sus **fuentes** y, si el coach no tenía información suficiente o el tema es
  legal/financiero, un botón «Agendar una mentoría» que lleva a la pestaña Mentorías. Si el servicio de IA no responde
  (`ai_unavailable` → `AssistantUnavailableFailure`) **nada quedó guardado**: se quita la burbuja, se avisa con un
  mensaje claro y el texto vuelve al campo para reenviarlo. «Nueva conversación» abre otra sin borrar la anterior. El icono de historial abre `/coach/conversations` (`GET /ai/conversations/me`) y elegir una
  reabre sus mensajes para continuarla (`OpenConversationUseCase`).
- **IA en tu celular** (descarga desde Perfil): la tarjeta `LocalAiSection` (de `ai_assistant`, exportada por su
  barrel) ofrece «Descargar IA», con confirmación del tamaño y la recomendación de usar Wi‑Fi. Se descargan dos modelos
  públicos sin token, Apache-2.0: **EmbeddingGemma 2 text 270m** (~165 MB, buscar en documentos) y **Gemma 4 E2B**
  (~2,6 GB, chat). Las URL y los tamaños se cambian con `--dart-define` (`LOCAL_AI_CHAT_URL`, `LOCAL_AI_EMBEDDER_URL`,
  `LOCAL_AI_CHAT_BYTES`, `LOCAL_AI_EMBEDDER_BYTES`; `core/config/app_config.dart`). La barra muestra el porcentaje
  total, ponderado por tamaño; «Cancelar descarga» detiene sin mostrar error (`LocalAiCancelledFailure`), y un corte
  se reintenta y continúa. Instalada, ofrece «Eliminar del celular». `LocalAiController` no se descarta al salir de
  Perfil: la descarga sigue mientras la app esté abierta. **Los modelos no se borran al cerrar sesión** (no son datos
  del usuario). Solo `data/datasources/local_ai_engine_data_source.dart` importa `flutter_edge_ai`.
- **Coach en el celular (RAG local):** con la IA instalada, el Coach responde **en el celular por defecto**
  (`coachModeProvider`); unos chips «En tu celular / En línea» permiten cambiar. Las reglas viven en
  `AskLocalCoachUseCase` (`domain`, Dart puro): busca los `topK` = 4 fragmentos más parecidos, descarta los de
  similitud < `LOCAL_AI_MIN_SIMILARITY` (0,45 por defecto, **sin calibrar con datos reales**: ajústalo en dispositivo)
  y, si no queda ninguno, responde el mismo texto que el servidor **sin llamar al modelo** (o, si el celular aún no
  tiene ninguna guía del CIE-U, `localCoachNoDocuments`, que lo explica). Los **saludos y la charla corta**
  («hola», «gracias», «¿qué puedes hacer?»; `isSmallTalk`) no pasan por la búsqueda: los contesta el modelo con un
  prompt corto, sin fuentes ni sugerencia de mentor. Pide un mentor si no hay
  fuentes o el tema es financiero/legal (mismas palabras clave que el backend). El prompt lleva el contexto
  `[Título] texto`, los últimos 6 turnos y la pregunta; si piden un plan, lo da en pasos con tiempos. La respuesta se
  ve **mientras se escribe** (`ChatState.partial`).
  - **Índice local:** `LocalKnowledgeRepositoryImpl.sync` baja `GET /ai/knowledge/index`, borra los documentos
    retirados, y de los nuevos o recargados pide `GET /ai/knowledge/{id}/fragments?incluir_embedding=false` y
    **calcula los vectores en el celular** con EmbeddingGemma (`retrievalDocument`; la pregunta con
    `retrievalQuery`). Así todo comparte un espacio vectorial; los vectores `nomic-embed-text` del servidor no se
    usan. Se guarda por documento en `coach_knowledge_index.json` (directorio de soporte de la app, `Float32` en
    base64), y si cambia el modelo de embeddings el índice se descarta. La búsqueda es coseno por fuerza bruta en
    memoria (suficiente para miles de fragmentos). Se sincroniza al terminar de instalar la IA y al abrir el Coach si
    pasaron 12 h (`LocalKnowledgeController.syncIfStale`); mientras el índice esté vacío, cada vez que se abre.
  - **Conversación local:** una sola, en `KeyValueStore` bajo `user.coach.local_conversation` (máx. 100 mensajes; se
    borra al cerrar sesión). «Nueva conversación» la borra. No llega al servidor, así que **no alimenta el análisis de
    sentimiento ni las alertas** (RF07); en línea todo sigue igual.
  - **Archivos propios del emprendedor** («Mis archivos para la IA», `/ai-files`, fuera de la barra inferior; se
    abre desde la tarjeta de Perfil y desde «Tus archivos» en el Coach): PDF, DOCX, TXT o MD de hasta 20 MB. El
    texto se extrae **en el celular** (`TextExtractor`), se trocea con `chunkText` (**copia fiel de `chunking.py`**:
    `test/features/ai_assistant/chunk_text_fixture.json` lo generó el backend y la prueba exige el mismo resultado),
    se embebe y se guarda en `coach_own_documents.json` dentro de `userFilesDirectory()` (`core/storage`). **El
    archivo no se copia ni se sube**; un PDF escaneado sin texto se explica. Mismo nombre = se reemplaza; tope de 400
    partes por archivo. El coach busca 4 fragmentos del CIE-U y 3 propios, los marca en el prompt como
    `[CIE-U: …]` y `[Tu archivo: …]` y le pide comparar los archivos con las guías para recomendar mejoras. Las
    fuentes propias se ven como «Tu archivo: …». Sin una guía del CIE-U que respalde la respuesta, sugiere un mentor.
  - **Al cerrar sesión** `LocalDataCleaner` borra también `userFilesDirectory()` (archivos propios), y el almacén
    descarta su copia en memoria si el archivo desapareció. El chat (`CoachChatController`) y la lista de archivos
    se reconstruyen cuando cambia el usuario (leen `authControllerProvider` por el barrel de `auth`). En pruebas de
    pantalla, `userFilesDirectoryProvider` devuelve un error sin E/S: la E/S real no termina bajo `testWidgets`.
  - Pendiente: probar en dispositivo real (memoria y velocidad de Gemma 4 E2B, umbral de similitud).
- **Necesidades y dificultades** (CU24, requiere conexión): feature `needs`. Perfil → «Necesidades y dificultades»
  (`/venture/needs`, solo con emprendimiento) lista lo reportado; «Reportar» (`/venture/needs/report`) pide tipo
  (necesidad o dificultad), rubro del catálogo del CIE-U (`GET /needs`), prioridad y descripción, y llama a
  `POST /ventures/{id}/needs`. `ReportNeedUseCase` valida rubro y descripción antes de llamar; una necesidad ya abierta
  del mismo rubro es `NeedAlreadyRegisteredFailure` (se puede repetir cuando el CIE-U la resuelva). Si el catálogo está
  vacío (el seed demo lo crea, las migraciones no) la pantalla lo explica.
- **Capacitaciones** (CU29, requiere conexión): feature `training`. Perfil → «Capacitaciones» (`/training`) combina
  `GET /training` con `GET /training/me` para marcar la inscripción y la asistencia propia (`asistencia`: `null` = sin
  registrar); la lista es **paginada** (20 por página, «Cargar más»: `TrainingsController.loadMore`); «Inscribirme» llama a `POST /training/{id}/enroll` y solo aparece en las `programadas`.
- **Documentos** (CU30, requiere conexión): Perfil → «Documentos» (`/venture/documents`, feature `documents`) lista todos los
  archivos del emprendimiento, sube con `EvidencePicker` y elimina los propios (`DELETE /documents/{id}`). «Abrir»
  (`OpenDocumentUseCase`) descarga con `GET /documents/{id}/download` a `userFilesDirectory()/documents/<id>_<nombre>`
  (se borra al cerrar sesión; un documento del servidor no cambia, así que la copia se reutiliza; la descarga va a un
  `.part` y se renombra al terminar) y lo abre con la app del sistema; sin app para ese tipo, se explica.
  La IA local reutiliza esa descarga (`downloadDocumentUseCaseProvider`, por el barrel) para analizar en el celular lo
  que el emprendedor ya subió: «Mis archivos para la IA» → «Agregar archivo» → «Desde los documentos de tu
  emprendimiento» (solo lista PDF, DOCX, TXT y MD).
- **Varios emprendimientos** (CU05): la coordinación puede poner a un emprendedor en más de un equipo.
  `myVenturesProvider` trae la lista, `selectedVentureIdProvider` guarda el elegido (también en el dispositivo, bajo `user.ventures.selected`: al reabrir la app se
  recuerda; si ya no es suyo, usa el primero) y `myVentureProvider` es el elegido o el primero. `VentureSwitcher` aparece en Inicio y en «Mi
  emprendimiento» solo con dos o más. Las features que dependen del emprendimiento (Camino, Mentorías, avances sin
  conexión, Coach) leen `currentVentureIdProvider` por el barrel de `ventures` y envían `emprendimiento_id`; para
  recargar los emprendimientos se invalida `myVenturesProvider`. «Mi emprendimiento» lista el equipo en solo lectura.
- **Perfil completo** (CU05, CU08, CU20; requiere conexión): la pestaña Perfil compone `MyVentureCard` (datos del
  emprendimiento y accesos), `XpBadgesSection` (resumen de XP, nivel, barra y «N de M insignias», de
  `GET /gamification/me`, con estado vacío y un botón a «Experiencia e insignias», `/xp`, pantalla a pantalla completa
  registrada en `gamificationDetailRoutes` fuera de la barra inferior: nivel, insignias con detalle en hoja inferior
  —criterio, XP y fecha— e historial de movimientos) y los botones de cuenta. «Editar emprendimiento»
  (`/venture/edit`) cambia nombre, sector y descripción con `PATCH /ventures/{id}`; la etapa y el estado los fija la
  coordinación y solo se muestran. «Hitos y evidencia» (`/venture/milestones`) lista los hitos y permite registrar uno,
  adjuntar evidencia (PDF, imagen u hoja de documento) y marcarlo cumplido. La evidencia es la feature `documents`:
  `POST /documents` multipart con `hito_id`. Si el hito se guarda pero la subida falla, el hito **se conserva**, se avisa y
  la evidencia se puede adjuntar después desde la tarjeta del hito.
- **Recuperación de contraseña** (CU01, requiere conexión): «¿Olvidaste tu contraseña?» del login → `/forgot-password`
  (`RequestPasswordResetUseCase`, `POST /auth/forgot-password`) → `/reset-password?email=` (`ResetPasswordUseCase`: valida
  que el código sean 6 dígitos y llama a `POST /auth/reset-password`) → login con un aviso. Ambas rutas son públicas en el
  `redirect` del router. El servidor responde igual exista o no la cuenta; `invalid_code` llega como `FieldFailure('code')`
  y se muestra en el campo del código, y `email_unavailable` como un mensaje claro. No inicia sesión: hay que entrar con la
  contraseña nueva.
- **Cambio de contraseña** (`/account/password`, desde la pestaña Perfil): `ChangePasswordUseCase`
  llama a `POST /auth/change-password`, **guarda el token nuevo** (el anterior deja de valer en
  el servidor) y la sesión sigue. «Contraseña actual incorrecta» es un 400 (`FieldFailure`), no
  cierra la sesión. El router solo reevalúa `redirect` cuando se abre o cierra la sesión, no con
  cada cambio del estado de auth (si no, reabría la ruta tras el `pop`).
- **Prueba contra el backend real** (opt-in):
  `API_BASE_URL=http://localhost:8000/api/v1 flutter test --tags integration test/integration`.

## 5. Reglas de la app móvil

1. **`main.dart` solo arranca la app.** Sin widgets de producto, sin lógica.
2. **`presentation` nunca habla con `data`.** Una pantalla o controlador usa
   *casos de uso* de `domain`. Si un controlador importa un `DataSource` o un DTO,
   está mal.
3. **`domain` es Dart puro**: sin `package:flutter/*`, sin `dio`, sin JSON. Solo
   entidades, contratos y casos de uso.
4. **DTO ≠ entidad.** `data/models/` mapea JSON del backend; `domain/entities/`
   es el objeto de negocio. El repositorio hace la conversión. Una entidad nunca
   lleva `fromJson`.
5. **Entre features, solo lo público.** Una feature no importa archivos internos de
   otra; lo compartido sube a `core/` o `shared/`.
6. **Nada de estado global suelto**: sin singletons ni variables globales mutables.
   Todo se obtiene por providers de Riverpod.
7. **Sin lógica de negocio en widgets.** Un `build()` lee estado y emite eventos;
   las decisiones viven en el controlador o el caso de uso.
8. **Cada feature registra sus rutas** en `app/router.dart` mediante una lista
   exportada por la feature. No se navega con rutas en crudo esparcidas por la UI.
9. **Errores**: la capa `data` captura excepciones y devuelve `Failure` de
   `core/error`. La UI no ve excepciones de red en bruto.
10. **Nombres de archivo en `snake_case`**, uno por clase pública.
11. **`test/` replica la estructura de `lib/`**: casos de uso y repositorios con
    test unitario; pantallas con widget test.
12. **`flutter analyze` y `flutter test` deben pasar** antes de dar un cambio por
    terminado. El código generado (`*.freezed.dart`, `*.g.dart`) se produce con
    `dart run build_runner build` y no se edita a mano.

### Notificaciones push (`features/notifications`)

- **Bandeja** (`/notifications`, se abre con la campana de Inicio, `NotificationsBell`): avisos del backend
  (`GET /notifications`), paginados, marcar uno o todos como leídos. Tocar un aviso abre su pantalla.
- **Push**: `PushGate` envuelve la app en `MaterialApp.builder` (en `app/app.dart`). Con sesión abierta llama a
  `PushController.onSession`: arranca Firebase, pide el permiso (Android 13+ / iOS), registra el token
  (`PUT /notifications/devices`) y lo vuelve a registrar si FCM lo renueva. Un push con la app abierta se muestra
  como `SnackBar` con «Ver»; tocar un push (app en segundo plano o cerrada) abre su ruta.
- **Rutas seguras**: la ruta del push pasa por `safeRoute` (solo prefijos conocidos de la app); otra se ignora.
- **Cerrar sesión** invalida el token de FCM (`deleteToken`): ya no hay JWT para borrar el dispositivo en el API, así
  que el backend lo borra cuando FCM le responde que el token no existe.
- **Sin Firebase** (`google-services.json` ausente, escritorio o pruebas): `start()` devuelve `false` y todo sigue con la
  bandeja. El valor por defecto de `pushMessagingProvider` es `DisabledPushMessaging`; `data` lo cambia por
  `FirebasePushMessaging`. Se usa el token clásico (`getToken`), que `firebase_messaging` 17 marca obsoleto: el backend
  envía al campo `token` de FCM HTTP v1.
- **Android**: `MainActivity` crea el canal `emprendeu_avisos` (el backend envía con ese `channel_id`); el manifiesto
  declara `POST_NOTIFICATIONS` y el canal por defecto. **iOS** necesita además `GoogleService-Info.plist`, la capacidad
  *Push Notifications* y la clave APNs en Firebase (ver `doc/notificaciones-push.md`).

