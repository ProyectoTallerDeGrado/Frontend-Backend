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

### Stack designado, aún **no instalado**

Hoy el proyecto solo tiene el contador por defecto en `lib/main.dart`. Para montar
la arquitectura hacen falta estas decisiones, que quedan fijadas aquí:

| Necesidad | Paquete designado | Alternativa descartada |
|---|---|---|
| Estado + inyección | **`flutter_riverpod`** | Bloc, Provider |
| Navegación | **`go_router`** | Navigator 1.0 a mano |
| HTTP | **`dio`** | `http` |
| Modelos / serialización | **`freezed`** + `json_serializable` + `build_runner` (dev) | clases a mano |
| Almacenamiento seguro (token) | **`flutter_secure_storage`** | `shared_preferences` para el token |
| Tests | `flutter_test` + `mocktail` (dev) | |

> Si el equipo prefiere **Bloc** en vez de Riverpod, hay que cambiarlo **en este
> documento primero** y luego escribir código. No se mezclan dos gestores de estado.

```bash
flutter pub add flutter_riverpod go_router dio flutter_secure_storage freezed_annotation json_annotation
flutter pub add --dev build_runner freezed json_serializable mocktail
```

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
│   ├── router.dart           # go_router: rutas agregadas desde cada feature
│   └── theme/                # ThemeData, tokens de color y tipografía
├── core/
│   ├── config/               # env, base url, flavors
│   ├── network/              # cliente Dio, interceptores (auth, logging), mapeo de errores
│   ├── error/                # Failure, excepciones
│   ├── storage/              # secure storage, caché local
│   └── utils/                # extensiones, formateadores
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
    └── widgets/              # widgets reutilizables entre features (botones, estados vacíos)
test/                         # espejo exacto de lib/
```

### Features previstas (mapa inicial — ajústalo con el usuario antes de implementar)

`auth`, `users`, `projects`, `mentoring`, `events` — los mismos nombres que los
módulos del backend y que las features de la web (regla global §4.6).
Registra aquí cada feature nueva.

## 4. Orden de construcción (primeros pasos)

1. Instalar el stack designado (§1) y vaciar `lib/main.dart` del contador demo.
2. `core/config` + `core/network` (Dio con base URL e interceptor de auth).
3. `app/app.dart`, `app/router.dart`, `app/theme/`.
4. Primera feature completa (`auth`) como plantilla de las demás.

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
    `dart run build_runner build --delete-conflicting-outputs` y no se edita a mano.
