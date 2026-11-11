# CU03 — Gestionar Roles y Permisos

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Administrador |
| Cliente | Web |
| Fase del plan | F1 |
| **Estado** | **✅ Completado** |

## Descripción

El administrador consulta los roles y edita la matriz de permisos `módulo × acción` de cada uno.

## Qué se hizo

- Catálogo fijo de permisos `modulo:accion` (7 módulos × 4 acciones) sembrado por migración.
- `GET /roles`, `GET /roles/{id}/permissions` y `PUT /roles/{id}/permissions` (reemplaza la matriz).
- Se rechazan permisos desconocidos y se evita que el administrador pierda su propio acceso (`AdminLockout`).
- Pantalla `/roles` con el editor de matriz; el menú y cada página se filtran con `hasPermission`.
- Los routers de todos los módulos usan `require_permission(...)`; el backend es la autoridad (403).

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/users/permissions.py` (catálogo), `Backend/EmprendeU/src/emprendeu/modules/users/dependencies.py` (`require_permission`), `Backend/EmprendeU/src/emprendeu/modules/users/router.py` (`roles_router`) |
| Migración | `db/migrations/versions/7a1c4f2b9d30_semilla_roles_y_permisos.py` |
| Web | `Frontend/emprendeu/features/users/components/permissions-editor.tsx`, `Frontend/emprendeu/features/users/roles.ts`, `Frontend/emprendeu/app/(app)/roles/page.tsx` |

## Por qué se hizo así

- Una matriz fija de acciones (`consulta`, `registro`, `modificacion`, `administrativo`) es fácil de razonar y coincide con las tablas `rol`/`permiso` del esquema `cieu`.
- El bloqueo del admin evita dejar el sistema sin nadie capaz de gestionar permisos.

## Verificación

- `Backend/EmprendeU/tests/test_users_admin_api.py::test_roles_y_matriz_de_permisos`, `test_matriz_rechaza_permisos_desconocidos_y_bloqueo_del_admin`

## Pendiente

- No se pueden crear roles nuevos desde la interfaz (los roles son los del esquema).
