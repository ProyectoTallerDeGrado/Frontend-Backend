# Notificaciones push de la app móvil

Fecha: 2026-11-17 · Rama: `feat/mejorUIUX`

## 1. Objetivo

El emprendedor recibe en el celular avisos de lo que pasa en su programa aunque tenga la app cerrada:

| Evento | Quién lo recibe | Abre |
|---|---|---|
| Mentoría agendada (por un compañero de equipo) | Los demás integrantes del emprendimiento | La sesión |
| Mentoría realizada o registrada por el mentor | Los emprendedores de la sesión | La sesión |
| Mentoría cancelada | Los emprendedores de la sesión (menos quien canceló) | La sesión |
| **Recordatorio**: mentoría en las próximas 24 h | Los emprendedores de la sesión | La sesión |
| Compromiso nuevo | El responsable (si no lo creó él mismo) | Tareas |
| **Recordatorio**: compromiso que vence en 48 h | El responsable | Tareas |
| Recomendación nueva del mentor | El equipo del emprendimiento | La sesión o el historial |
| Capacitación nueva | Todos los emprendedores activos | Capacitaciones |
| Inscripción hecha por coordinación | Ese emprendedor | Capacitaciones |
| El emprendimiento avanzó de etapa | El equipo | Inicio |
| Insignia ganada por algo que hizo otra persona (asistir a una mentoría) | Ese emprendedor | Perfil |

Quien hace la acción nunca recibe su propio aviso. Cada aviso también queda en una **bandeja** dentro de la app
(campana en Inicio), así que no se pierde nada si el push no llega o Firebase no está configurado.

## 2. Decisiones

- **Transporte: Firebase Cloud Messaging (FCM)**, elegido por el usuario. Es gratis y es la única forma de que Android
  muestre avisos con la app cerrada. El backend envía con la **API HTTP v1** firmando un JWT RS256 con la cuenta de
  servicio (`pyjwt[crypto]`). No se agregó el SDK `firebase-admin`.
- **Bandeja en la base de datos** (`notificaciones`): el push es solo el «timbre» y el contenido vive en el backend.
- **El push sale después del commit.** `NotificationService.notify` guarda el aviso dentro de la transacción de quien
  lo llama y deja el mensaje en `session.info`. Un listener `after_commit` lo envía en segundo plano. Si la operación
  falla y se revierte, no sale ningún push de algo que no ocurrió.
- **Todo es opcional:**
  - Sin `FCM_CREDENTIALS_FILE`, el backend no envía nada.
  - Sin `google-services.json`, la app compila sin el plugin de Google Services y solo usa la bandeja.
- **Recordatorios sin duplicados**: cada uno lleva una clave (`sesion:<id>`, `compromiso:<id>`) única por usuario.
  La tarea puede correr cada hora sin repetir avisos.
- **Seguridad**:
  - Un token FCM pertenece a una sola cuenta: si otra persona inicia sesión en el mismo celular, el token pasa a ella.
  - Al cerrar sesión, la app invalida su token y el backend lo borra cuando FCM responde `UNREGISTERED`.
  - La app solo navega a rutas conocidas (`safeRoute`).
- **Con la app abierta** el aviso se muestra como `SnackBar` con «Ver», sin `flutter_local_notifications`.

## 3. Fases realizadas

### Fase 1 — Backend: módulo `notifications`
- `modules/notifications/`, con estos archivos:
  - `models.py`: tablas `notificaciones` y `dispositivos_push`.
  - `repository.py` y `service.py` (`NotificationService.notify`).
  - `schemas.py`, `router.py` y `exceptions.py`.
  - `push.py`: `FcmSender`, `PushDispatcher`, el gancho `after_commit`, `set_push_dispatcher` y `wait_for_pushes`.
- Endpoints (cualquier usuario autenticado, cada uno solo ve lo suyo):
  - `GET /api/v1/notifications?page=&page_size=&solo_no_leidas=` → página `{items, page, page_size, total}`
  - `GET /api/v1/notifications/unread-count` → `{"no_leidas": n}`
  - `POST /api/v1/notifications/{id}/read` y `POST /api/v1/notifications/read-all`
  - `PUT /api/v1/notifications/devices` `{token, plataforma: "android"|"ios"}` → 204
  - `DELETE /api/v1/notifications/devices/{token}` → 204
- Migración `4941fe5dc407` (sobre `509235c3a151`).
- Configuración: `FCM_CREDENTIALS_FILE` y `FCM_TIMEOUT_SECONDS` en `core/config.py`, `.env.example` y `docker-compose.yml`.
- Dependencia: `pyjwt[crypto]`, que agrega `cryptography` para firmar con RS256.

### Fase 2 — Backend: eventos y recordatorios
- Avisos agregados en los servicios existentes, siempre antes de su `commit`:
  - `mentoring/service.py`: agendar, completar, registrar, cancelar, compromiso y recomendación.
  - `training/service.py`: crear capacitación e inscribir a un participante.
  - `ventures/service.py`: cambio de etapa.
  - `gamification/service.py`: `award_event`.
- `entrepreneurs` expone `active_user_ids()`, usado para avisar de una capacitación nueva.
- Recordatorios:
  - `MentoringService.send_reminders()` envía las mentorías de las próximas 24 h y los compromisos que vencen en 48 h.
  - La tarea `python -m emprendeu.modules.mentoring.jobs` los ejecuta.
  - En Docker corre como el servicio `reminders-job`, cada `REMINDERS_INTERVAL_SECONDS` (por defecto 3600).

### Fase 3 — App móvil: feature `notifications`
- `firebase_core` 5.2 y `firebase_messaging` 17.1.
- Capas:
  - `domain`: `AppNotification`, `PushNotice`, `safeRoute`, `NotificationsRepository`, `PushMessaging` (con
    `DisabledPushMessaging`) y los casos de uso.
  - `data`: DTO freezed, `NotificationsRemoteDataSource`, `FirebasePushMessaging` y la implementación del repositorio.
  - `presentation`:
    - Bandeja (`NotificationsScreen`, ruta `/notifications`).
    - Campana con contador (`NotificationsBell`, en el encabezado de Inicio).
    - `PushController` y `PushGate`, montado en `MaterialApp.builder`.
- Comportamiento:
  - Al iniciar sesión, la app pide permiso y registra el token.
  - Si FCM renueva el token, lo vuelve a registrar.
  - Con la app abierta, un push se muestra como `SnackBar` con «Ver».
  - Tocar un push abre la pantalla correspondiente.
  - Al cerrar sesión, invalida el token.

### Fase 4 — Android
- `settings.gradle.kts` declara el plugin `com.google.gms.google-services` 4.4.4. `app/build.gradle.kts` solo lo
  aplica si existe `app/google-services.json`.
- `AndroidManifest.xml`: permiso `POST_NOTIFICATIONS` y canal por defecto `emprendeu_avisos`.
- `MainActivity.kt` crea el canal «Avisos de EmprendeU», con importancia alta.

### Fase 5 — Documentación
- Este archivo.
- `AGENTS.md` (raíz, backend y móvil), con el módulo, las tablas, los endpoints, las convenciones y el paquete nuevo.

## 4. Cómo activarlo

### Firebase (una vez)
1. Entra en <https://console.firebase.google.com> y crea un proyecto (Analytics no hace falta).
2. **Agrega una app Android** con el paquete `com.example.app_emprendeu`, el `applicationId` actual.
   - Si cambias el `applicationId`, cambia también el paquete en Firebase.
   - Descarga `google-services.json` a `Frontend/app_emprendeu/android/app/`.
3. **Cuenta de servicio del backend**:
   - Ve a *Configuración del proyecto → Cuentas de servicio → Generar nueva clave privada*.
   - Guarda el JSON **fuera del repositorio** (es una credencial) y define `FCM_CREDENTIALS_FILE=/ruta/al/archivo.json`
     en `Backend/EmprendeU/.env`.
   - Con Docker, monta el archivo como volumen en los servicios `api` y `reminders-job` y usa la ruta de dentro del
     contenedor.
4. Corre `uv run alembic upgrade head` y reinicia la API.
5. Vuelve a compilar la app con `flutter run`. Al entrar, pedirá permiso para mostrar notificaciones.
6. Programa los recordatorios con un cron cada hora: `uv run python -m emprendeu.modules.mentoring.jobs`.
   Con Docker no hace falta, porque los ejecuta `reminders-job`.

### iOS (pendiente de configurar en una Mac)
- Agrega `GoogleService-Info.plist` en `ios/Runner/`.
- Activa *Push Notifications* y *Background Modes → Remote notifications* en Xcode.
- Sube la clave APNs (.p8) en Firebase → *Cloud Messaging*.

El código ya maneja iOS (`plataforma: "ios"` y envío APNs con sonido), pero no se pudo probar sin una Mac.

## 5. Verificación (salidas reales)

- **Backend**:
  - `uv run ruff check src tests`: `All checks passed!`
  - `uv run alembic check`: `No new upgrade operations detected.`
  - `uv run pytest`: **`149 passed`**, 8 de ellos nuevos.
  - Tests de la API (`tests/test_notifications_api.py`):
    - Registrar, reasignar y borrar dispositivos.
    - Avisos de mentoría, con la bandeja, el contador y marcar como leído (uno o todos). Una cuenta no puede marcar
      un aviso ajeno.
    - Avisos de etapa, insignia, capacitación nueva e inscripción, con la hora en La Paz.
    - Recordatorios que salen una sola vez.
    - Sin commit no sale ningún push.
    - El despachador borra los tokens inválidos.
  - Tests del cliente FCM (`modules/notifications/tests/test_push.py`), sin red:
    - Comprueban la firma del JWT y el reuso del token OAuth.
    - Comprueban el formato del mensaje.
    - Comprueban cómo se clasifican `UNREGISTERED`, `INVALID_ARGUMENT` y 503.
- **Contra la API de desarrollo** (`emprendedor@emprendeu.bo`):
  - `unread-count` respondió `{"no_leidas":1}` y la bandeja devolvió el recordatorio creado por la tarea.
  - `PUT` y `DELETE /notifications/devices` respondieron 204.
  - La tarea de recordatorios, corrida una vez, registró `sesiones=1 compromisos=0`.
- **Móvil**:
  - `flutter analyze`: `No issues found!`
  - `flutter test`: **`All tests passed!`**, con 202 tests, 7 de ellos nuevos.
    - `safeRoute`.
    - Campana con contador y bandeja, incluido «Marcar todo leído».
    - Tocar un aviso lo marca y navega.
    - Bandeja vacía.
    - Registro y renovación del token, y `SnackBar` del push con la app abierta.
    - Cerrar sesión invalida el token.
    - Sin Firebase no se registra nada.
  - `flutter build apk --debug` compila sin `google-services.json`, y también con uno de prueba, que se borró después:
    el plugin es compatible con AGP 9.1.
- **No probado**: la entrega real de un push en un celular, porque no hay un proyecto Firebase ni una cuenta de
  servicio en este entorno.

## 6. Mantenimiento

- **Nuevo tipo de aviso:**
  - Llama a `NotificationService(session).notify(...)` antes del `commit` del servicio.
  - Usa una ruta que exista en la app y esté en `_allowedRoutePrefixes`
    (`features/notifications/domain/entities/app_notification.dart`).
  - Agrega su ícono en `_iconFor` (`notifications_screen.dart`) si corresponde.
- **En tests de backend:** el `client` ya instala `FakePushDispatcher` (`app.state.fake_push`). Llama
  `await wait_for_pushes()` antes de comprobar lo que se envió.
- **Token de FCM:** se usa el token de registro clásico (`getToken`), que `firebase_messaging` 17 marca como obsoleto
  en favor de `register()` y el Installation ID. Si se migra, también cambia lo que el backend envía a FCM.
