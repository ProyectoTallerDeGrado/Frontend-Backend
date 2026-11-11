# CU04 — Registrar Emprendedor

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Coordinador |
| Cliente | Web |
| Fase del plan | F4 |
| **Estado** | **✅ Completado** |

## Descripción

La coordinación registra a un emprendedor: crea su cuenta de usuario y su perfil en una sola operación.

## Qué se hizo

- `POST /entrepreneurs` crea `usuario` + `emprendedor` en la **misma transacción** (todo o nada).
- Rechaza un documento de identidad ya registrado (`DocumentAlreadyRegistered`, 409) y un correo repetido.
- Devuelve la clave temporal, que la web muestra una sola vez.
- `GET /entrepreneurs` con búsqueda por nombre, correo o documento; `GET/PATCH /entrepreneurs/me` para el propio perfil.
- Pantalla `/entrepreneurs` con la hoja «Nuevo emprendedor» (requiere `emprendedores:registro`).

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/entrepreneurs/` (`router.py`, `service.py`, `repository.py`, `exceptions.py`) |
| Web | `Frontend/emprendeu/features/entrepreneurs/` (`entrepreneurs-screen.tsx`, `register-entrepreneur-sheet.tsx`, `server/actions.ts`), `Frontend/emprendeu/app/(app)/entrepreneurs/page.tsx` |

## Por qué se hizo así

- La transacción única evita usuarios huérfanos sin perfil si algo falla a la mitad.
- El documento único lo pide el caso de uso: una persona no puede inscribirse dos veces.

## Verificación

- `Backend/EmprendeU/tests/test_entrepreneurs_api.py::test_cu04_registrar_emprendedor_documento_unico_y_todo_o_nada`

## Pendiente

- Ninguno para el caso. La admisión por postulación (CU26) es un caso aparte, aún no iniciado.
