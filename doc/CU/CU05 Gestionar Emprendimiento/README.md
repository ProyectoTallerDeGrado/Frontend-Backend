# CU05 — Gestionar Emprendimiento

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Coordinador (web) y emprendedor (app) |
| Cliente | Web y app móvil |
| Fase del plan | F4 |
| **Estado** | **✅ Completado** |

## Descripción

Crear, consultar y editar emprendimientos. El emprendedor solo ve y edita el suyo, sin tocar campos reservados.

## Qué se hizo

- `POST /ventures`, `GET /ventures` (paginado), `GET /ventures/me`, `GET/PATCH /ventures/{id}`.
- El emprendedor solo accede a su emprendimiento; si intenta cambiar campos de la coordinación (estado, etapa) recibe `ReservedFields` (403).
- Web `/ventures`: lista, «Nuevo emprendimiento» (eligiendo emprendedor) y «Editar» (nombre, sector, descripción y estado).
- Móvil: tarjeta para crear el emprendimiento (`CreateVentureCard`), `MyVentureCard` en Perfil y pantalla `/venture/edit` (nombre, sector, descripción).

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/ventures/` (`router.py`, `service.py` → `create`, `update`, `mine`; `exceptions.py`) |
| Web | `Frontend/emprendeu/features/ventures/` (`ventures-screen.tsx`, `venture-form-sheet.tsx`, `server/actions.ts`), `Frontend/emprendeu/app/(app)/ventures/page.tsx` |
| Móvil | `Frontend/app_emprendeu/lib/features/ventures/` (`create_venture_usecase.dart`, `update_venture_usecase.dart`, `edit_venture_screen.dart`, `my_venture_card.dart`, `create_venture_card.dart`) |

## Por qué se hizo así

- Separar campos del emprendedor y de la coordinación protege datos de seguimiento (etapa, estado) que solo debe fijar el CIE-U.
- La regla vive en el servicio del backend, así ambos clientes la heredan.

## Verificación

- `Backend/EmprendeU/tests/test_entrepreneurs_api.py::test_cu05_emprendimiento_propio_y_campos_reservados`
- `Backend/EmprendeU/tests/test_audit_ventures_api.py::test_emprendedor_crea_su_emprendimiento_y_ve_su_etapa`
- `Frontend/app_emprendeu/test/features/ventures/` (casos de uso y pantallas)

## Pendiente

- Ninguno conocido.
