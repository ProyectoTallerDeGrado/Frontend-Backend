# CU24 — Registrar Necesidades y Dificultades

| Campo | Valor |
|---|---|
| Prioridad | Media |
| Actor(es) | Emprendedor |
| Cliente | App móvil |
| Fase del plan | F6 |
| **Estado** | **✅ Completado** |

## Descripción

El emprendedor registra las necesidades o dificultades de su emprendimiento para que el CIE-U las atienda.

## Qué se hizo

- **Backend hecho:** catálogo `GET/POST /needs` (`necesidades`), `GET/POST /ventures/{id}/needs` (`emprendimiento_necesidades`) y `PATCH /venture-needs/{id}/resolve` para marcarla resuelta.
- **App móvil:** feature `needs` (Perfil → «Necesidades y dificultades»): lista lo reportado y «Reportar» pide tipo, rubro del catálogo, prioridad y descripción.
- **Web:** bandeja `/needs` para el personal, con filtros por estado y tipo y el botón «Marcar resuelta».

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/ventures/router.py` (rutas `/needs`, `/venture-needs`), `Backend/EmprendeU/src/emprendeu/modules/ventures/service.py` (`list_needs`, `create_need`, `add_venture_need`, `resolve_venture_need`) |
| Móvil | `Frontend/app_emprendeu/lib/features/needs/` |
| Web | `Frontend/emprendeu/features/ventures/components/needs-screen.tsx`, `resolve-need-button.tsx`; página `app/(app)/needs/page.tsx` |

## Por qué se hizo así

- Las tablas existían en el esquema `cieu` y se expusieron junto con el resto de `ventures` en la fase 3 del backend.

## Verificación

- `Backend/EmprendeU/tests/test_audit_ventures_api.py::test_cambio_de_etapa_hitos_y_necesidades`
- `Frontend/app_emprendeu/test/features/needs/` (casos de uso y pantallas)

## Pendiente

- Probar a mano el flujo de punta a punta.
