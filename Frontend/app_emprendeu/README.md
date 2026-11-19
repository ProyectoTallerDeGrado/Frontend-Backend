# EmprendeU — app móvil

App del emprendedor (Flutter). Arquitectura y reglas en `AGENTS.md`.

## Requisitos

- **Flutter `>=3.50.0`** (Dart `^3.13.5`). Todo el equipo debe usar la misma versión
  estable: si el build de Android falla por versiones de Gradle, AGP o Kotlin,
  ejecuta `flutter upgrade` y luego `flutter clean`.
- Versiones de Android fijadas en el repo: Gradle `9.5.0`, AGP `9.1.1`, Kotlin `2.4.20`.
  Súbelas junto con Flutter cuando una versión nueva las exija.

## Ejecutar

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```
