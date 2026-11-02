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
│   └── theme/                # ThemeData, tokens de color y tipografía
├── core/
│   ├── config/               # env, base url, flavors
│   ├── network/              # cliente Dio, AuthInterceptor, eventos de sesión, mapeo de errores
│   ├── error/                # Failure, Result
│   ├── storage/              # token seguro, KeyValueStore (cola/cachés), LocalDataCleaner
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
    └── widgets/              # AppShell y AppBottomNav; widgets reutilizables entre features
test/                         # espejo exacto de lib/
```

### Features previstas (mapa inicial — ajústalo con el usuario antes de implementar)

`auth` ✅, `ventures` ✅ (editar, hitos), `gamification` ✅ (Camino, XP e insignias), `mentoring` ✅ (compromisos y avances, agendar y ver sesiones, historial),
`documents` ✅ (evidencia de hitos), `ai_assistant` ✅ (Coach IA), `home` ✅ — los mismos nombres que los módulos del backend y que las features de la web
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
- **Historial del emprendimiento** (CU19, requiere conexión): botón «Ver historial del emprendimiento» en
  Mentorías → `/mentoring/history`, que llama a `GET /mentoring/ventures/me/history?orden=` (`GetHistoryUseCase`,
  `HistoryEvent`) y deja alternar entre «Más reciente primero» y «Cronológico».
- **Coach IA** (CU11, requiere conexión): la pestaña «Coach» (`/coach`) abre la conversación más reciente
  (`GET /ai/conversations/me` y sus mensajes) o una invitación con preguntas sugeridas. `AskCoachUseCase` valida el texto
  (no vacío, máximo 2000) y `POST /ai/chat` lleva **plazo propio de 90 s** (el modelo local tarda más que una consulta
  normal). Cada respuesta muestra sus **fuentes** y, si el coach no tenía información suficiente o el tema es
  legal/financiero, un botón «Agendar una mentoría» que lleva a la pestaña Mentorías. Si el servicio de IA no responde
  (`ai_unavailable` → `AssistantUnavailableFailure`) **nada quedó guardado**: se quita la burbuja, se avisa con un
  mensaje claro y el texto vuelve al campo para reenviarlo. «Nueva conversación» abre otra sin borrar la anterior.
- **Perfil completo** (CU05, CU08, CU20; requiere conexión): la pestaña Perfil compone `MyVentureCard` (datos del
  emprendimiento y accesos), `XpBadgesSection` (XP, nivel, barra hacia el siguiente nivel, insignias obtenidas y
  últimos movimientos, de `GET /gamification/me`) y los botones de cuenta. «Editar emprendimiento»
  (`/venture/edit`) cambia nombre, sector y descripción con `PATCH /ventures/{id}`; la etapa y el estado los fija la
  coordinación y solo se muestran. «Hitos y evidencia» (`/venture/milestones`) lista los hitos y permite registrar uno,
  adjuntar evidencia (PDF, imagen u hoja de documento) y marcarlo cumplido. La evidencia es la feature `documents`:
  `POST /documents` multipart con `hito_id`. Si el hito se guarda pero la subida falla, el hito **se conserva**, se avisa y
  la evidencia se puede adjuntar después desde la tarjeta del hito.
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
