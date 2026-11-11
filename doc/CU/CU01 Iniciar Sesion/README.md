# CU01 — Iniciar Sesión

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Todos (administrador, coordinador, asesor, emprendedor) |
| Cliente | Web y app móvil |
| Fase del plan | F1 |
| **Estado** | **✅ Completado** |

## Descripción

El usuario se autentica con correo y contraseña y recibe un JWT que usa en cada petición.

## Qué se hizo

- `POST /api/v1/auth/login` valida credenciales (hash con bcrypt) y devuelve un JWT de acceso.
- `GET /auth/me` devuelve el usuario y sus permisos; `POST /auth/register` crea un emprendedor y entra.
- Bloqueo por intentos fallidos (limitador de ventana deslizante) y rechazo de cuentas deshabilitadas, también con un token ya emitido.
- `POST /auth/change-password`: guarda `usuario.password_changed_at`, invalida los tokens anteriores y devuelve uno nuevo.
- Web: login solo para personal (un emprendedor recibe «usa la app móvil»); el JWT vive en la cookie `httpOnly` `emprendeu_session` y `proxy.ts` protege las rutas.
- Móvil: login solo para emprendedores (`WrongPlatformFailure` para el personal); el token va a `flutter_secure_storage` y se restaura al abrir la app.
- El login y los cambios quedan en la auditoría.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/users/router.py` (`auth_router`), `Backend/EmprendeU/src/emprendeu/modules/users/service.py`, `Backend/EmprendeU/src/emprendeu/modules/users/dependencies.py` |
| Backend (núcleo) | `Backend/EmprendeU/src/emprendeu/core/security.py` (JWT, hash), `core/ratelimit.py` (intentos) |
| Migración | `db/migrations/versions/b7d2e5a91c34_usuario_password_changed_at.py` |
| Web | `Frontend/emprendeu/features/auth/` (`login-form.tsx`, `server/actions.ts`, `server/session.ts`, `server/authed-fetch.ts`), `Frontend/emprendeu/proxy.ts`, `Frontend/emprendeu/app/(public)/login/page.tsx`, `/account` |
| Móvil | `Frontend/app_emprendeu/lib/features/auth/` (`login_usecase.dart`, `restore_session_usecase.dart`, `change_password_usecase.dart`, `login_screen.dart`), `lib/core/network/auth_interceptor.dart`, `lib/core/storage/token_storage.dart` |

## Por qué se hizo así

- JWT de acceso único sin *refresh token*: suficiente para el alcance y más simple (decisión registrada en `ROADMAP.md`).
- La cookie `httpOnly` evita que el navegador vea el token; todo pasa por server actions.
- Cada cliente acepta solo su rol (regla de alcance del plan: web para el personal, app para el emprendedor).
- `password_changed_at` resuelve el hallazgo de auditoría «los tokens siguen válidos tras cambiar la contraseña».

## Verificación

- `Backend/EmprendeU/tests/test_auth_api.py` (login incorrecto, cuenta deshabilitada, `/me`, cambio de clave invalida tokens)
- `Backend/EmprendeU/tests/test_audit_ventures_api.py::test_bloqueo_por_intentos_de_login`, `test_login_y_cambios_quedan_en_auditoria`
- `Backend/EmprendeU/tests/test_infra.py` (hash, token ida y vuelta, secreto fuerte)
- `Frontend/app_emprendeu/test/features/auth/` (casos de uso, validadores, pantallas) y `Frontend/app_emprendeu/test/integration/auth_backend_test.dart` (opt-in)

## Pendiente

- Recuperación de contraseña por correo: fuera de alcance (requiere servicio de correo).
- El limitador de intentos está en memoria: con varias réplicas hay que moverlo a Redis.
