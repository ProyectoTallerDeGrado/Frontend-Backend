# CU03 — Gestionar Roles y Permisos

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Administrador |
| Cliente | Web |
| Fase del plan | F1 |
| **Estado** | **✅ Completado (con mejoras)** |

## Descripción

El administrador consulta los roles, edita la matriz de permisos `módulo × acción` de cada uno y puede **crear, copiar y eliminar roles personalizados** (por ejemplo, un rol «solo lectura»). Cada usuario tiene un solo rol; sus permisos son los del rol.

## Qué se hizo

### Base (primera entrega)

- Catálogo fijo de permisos `modulo:accion` (7 módulos × 4 acciones) sembrado por migración.
- `GET /roles`, `GET /roles/{id}/permissions` y `PUT /roles/{id}/permissions` (reemplaza la matriz).
- Se rechazan permisos desconocidos y se evita que el administrador pierda su propio acceso (`AdminLockout`).
- Pantalla `/roles` con el editor de matriz; el menú y cada página se filtran con `hasPermission`.
- Los routers de todos los módulos usan `require_permission(...)`; el backend es la autoridad (403).

### Mejoras (segunda entrega)

1. **Bloqueo del administrador más completo.** El rol `administrador` debe conservar `usuarios:consulta` **y** `usuarios:administrativo`. Antes solo se exigía el segundo y el administrador podía quitarse la consulta, perdiendo el acceso a `/users` y `/roles`. Error: 409 `admin_lockout`.
2. **Roles personalizados (CRUD).**
   - `POST /roles`: nombre único (se guarda en minúsculas; letras, números, espacios, `-` y `_`), descripción opcional y `clonar_de` para copiar la matriz de otro rol.
   - `PATCH /roles/{id}`: cambia nombre o descripción.
   - `DELETE /roles/{id}`: solo si no tiene usuarios asignados.
   - Los cuatro roles del sistema (`administrador`, `coordinador`, `asesor`, `emprendedor`) no se renombran ni se eliminan (409 `system_role_protected`).
   - Los tres endpoints exigen `usuarios:administrativo` y quedan en la auditoría (`roles.crear`, `roles.editar`, `roles.eliminar`).
   - Errores: 409 `role_name_taken`, 409 `role_in_use`, 404 si el rol no existe.
3. **Interfaz web.**
   - `/roles`: botón **Nuevo rol** (panel lateral con nombre, descripción, «Copiar permisos de» y plantilla «Solo lectura» o «Sin permisos») y botón **Eliminar rol** en los roles personalizados (deshabilitado si tienen usuarios). Ambos solo se ven con `usuarios:administrativo`.
   - `/users`: el selector de rol, el filtro y el alta de usuario usan la lista real de roles (`GET /roles`), así que un rol nuevo se puede asignar enseguida. Los roles personalizados tienen un color propio y su nombre se muestra con la primera letra en mayúscula.
   - El texto «se aplican en el siguiente acceso» se cambió por «de inmediato»: el backend relee los permisos del usuario en cada petición.
4. **Menú coherente con la pantalla.** «Mi disponibilidad» solo aparece para el rol `asesor` (la pantalla ya lo exigía), con la nueva propiedad `onlyForRole` en el menú.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/users/` → `permissions.py` (`SYSTEM_ROLES`, `ADMIN_REQUIRED`), `exceptions.py` (`RoleNameTaken`, `RoleInUse`, `SystemRoleProtected`), `repository.py` (`create_role`, `update_role`, `delete_role`, `count_role_users`), `schemas.py` (`RoleCreate`, `RoleEdit`), `service.py` (`create_role`, `edit_role`, `delete_role`, `set_role_matrix`), `router.py` (`roles_router`) |
| Migración | `db/migrations/versions/7a1c4f2b9d30_semilla_roles_y_permisos.py` (sin cambios: los roles nuevos usan las tablas `rol` y `rol_permiso` existentes, no hay migración nueva) |
| Web | `Frontend/emprendeu/features/users/components/permissions-editor.tsx`, `new-role-drawer.tsx` (nuevo), `user-row-controls.tsx`, `user-filters.tsx`, `users-table.tsx`, `users-view.tsx`, `new-user-drawer.tsx`; `features/users/roles.ts`, `server/actions.ts` (`createRoleAction`, `deleteRoleAction`); `app/(app)/layout.tsx`, `app/(app)/roles/page.tsx` |

## Por qué se hizo así

- **Una matriz fija de acciones** (`consulta`, `registro`, `modificacion`, `administrativo`) es fácil de razonar y coincide con las tablas `rol`/`permiso` del esquema `cieu`.
- **Permisos por rol y no por usuario.** Para dar «solo lectura» a una persona concreta se crea un rol y se le asigna. Evita una tabla de excepciones por usuario (migración, cambios en `CurrentUser` y otra interfaz) y mantiene el modelo actual.
- **El rol nuevo ya funciona sin tocar el resto.** `CurrentUser.is_staff` trata como personal a todo rol distinto de `emprendedor`, y `change_role` acepta cualquier rol existente.
- **El bloqueo del administrador** evita dejar el sistema sin nadie capaz de gestionar permisos ni de entrar a la pantalla de roles.
- **Proteger los roles del sistema** porque el código los referencia por nombre (`ADMIN_ROLE`, `DEFAULT_ROLE`, el registro público, `MOBILE_ONLY_ROLE` en la web).
- **Backend como autoridad:** la interfaz oculta o deshabilita, pero cada endpoint devuelve 403 sin el permiso.

## Verificación

- `Backend/EmprendeU/tests/test_users_admin_api.py`, 3 tests nuevos además de los existentes:
  - `test_admin_no_puede_perder_usuarios_consulta`
  - `test_crud_de_roles_personalizados` (crear, clonar, duplicado, editar, rol del sistema, eliminar)
  - `test_rol_con_usuarios_no_se_elimina_y_rol_solo_lectura_no_escribe` (un usuario con rol «solo lectura» lee y recibe 403 al escribir)
- Resultado verificado al hacer el cambio: `uv run pytest` → 81 pasaron; `ruff check` y `ruff format --check` limpios; en la web `tsc --noEmit` y `pnpm lint` sin errores.
- **No se probó en el navegador** la interfaz nueva (Nuevo rol, Eliminar rol, selector de roles en `/users`).

## Pendiente

- La interfaz no ofrece **renombrar** un rol (`PATCH /roles/{id}` existe en el backend).
- La web no tiene runner de tests: faltan pruebas de componentes (casillas deshabilitadas sin permiso, botón «Nuevo rol» oculto).
- No hay **permisos por usuario**: un usuario tiene un solo rol.
- La **app móvil** guarda `permisos` del usuario pero no filtra pantallas con ellos.
