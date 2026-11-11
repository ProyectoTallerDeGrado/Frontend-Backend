# CU02 — Gestionar Usuarios

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Administrador |
| Cliente | Web |
| Fase del plan | F1 |
| **Estado** | **✅ Completado** |

## Descripción

El administrador lista, crea, habilita/deshabilita y cambia el rol de las cuentas.

## Qué se hizo

- `GET /users` con búsqueda, filtro por rol y paginación estándar (`items, page, page_size, total`).
- `POST /users` crea la cuenta con una **clave temporal** que se muestra una sola vez.
- `PATCH /users/{id}/estado` habilita o deshabilita (no puedes deshabilitarte a ti mismo).
- `PATCH /users/{id}/rol` cambia el rol (así una cuenta registrada llega a usar el panel).
- Pantalla `/users` con tabla, filtros en la URL, búsqueda con *debounce* y cajón «Nuevo usuario».
- Todas las acciones exigen permisos `usuarios:*` y quedan en la auditoría.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/users/router.py` (`users_router`), `Backend/EmprendeU/src/emprendeu/modules/users/service.py`, `Backend/EmprendeU/src/emprendeu/modules/users/repository.py`, `Backend/EmprendeU/src/emprendeu/modules/users/schemas.py`, `Backend/EmprendeU/src/emprendeu/modules/users/cli.py` (`create-admin`) |
| Web | `Frontend/emprendeu/features/users/` (`users-view.tsx`, `users-table.tsx`, `user-filters.tsx`, `user-row-controls.tsx`, `new-user-drawer.tsx`, `server/actions.ts`, `server/queries.ts`), `Frontend/emprendeu/app/(app)/users/page.tsx` |

## Por qué se hizo así

- Clave temporal en vez de invitación por correo: no hay servicio de correo en el alcance.
- Impedir deshabilitarse a uno mismo evita que el sistema quede sin administrador.
- Filtros en la URL: la página se renderiza en el servidor y los enlaces son compartibles.

## Verificación

- `Backend/EmprendeU/tests/test_users_admin_api.py` (permisos, listado con búsqueda y paginación, clave temporal, no deshabilitarse)

## Pendiente

- La web aún no tiene pruebas automatizadas (Vitest/Playwright, fase 7 del plan).
