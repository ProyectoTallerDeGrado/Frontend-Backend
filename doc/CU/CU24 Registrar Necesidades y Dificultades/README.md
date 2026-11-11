# CU24 — Registrar Necesidades y Dificultades

| Campo | Valor |
|---|---|
| Prioridad | Media |
| Actor(es) | Emprendedor |
| Cliente | App móvil |
| Fase del plan | F6 |
| **Estado** | **🟡 Parcial** |

## Descripción

El emprendedor registra las necesidades o dificultades de su emprendimiento para que el CIE-U las atienda.

## Qué se hizo

- **Backend hecho:** catálogo `GET/POST /needs` (`necesidades`), `GET/POST /ventures/{id}/needs` (`emprendimiento_necesidades`) y `PATCH /venture-needs/{id}/resolve` para marcarla resuelta.
- **Clientes no hechos:** ni la app móvil ni la web tienen pantalla para registrar o ver necesidades.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/ventures/router.py` (rutas `/needs`, `/venture-needs`), `Backend/EmprendeU/src/emprendeu/modules/ventures/service.py` (`list_needs`, `create_need`, `add_venture_need`, `resolve_venture_need`) |
| Móvil | — (falta crear en `Frontend/app_emprendeu/lib/features/ventures/`) |

## Por qué se hizo así

- Las tablas existían en el esquema `cieu` y se expusieron junto con el resto de `ventures` en la fase 3 del backend.

## Verificación

- `Backend/EmprendeU/tests/test_audit_ventures_api.py::test_cambio_de_etapa_hitos_y_necesidades`

## Pendiente

- Pantalla en la app móvil para registrar una necesidad (elegir del catálogo o crear una nueva) y ver su estado.
- Opcional: vista en la web para que la coordinación resuelva las necesidades.
- Pruebas de la pantalla y cierre en el tablero (fase 6 del plan).
