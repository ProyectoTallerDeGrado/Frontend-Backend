# CU22 — Consultar Tareas y Compromisos Pendientes

| Campo | Valor |
|---|---|
| Prioridad | Media |
| Actor(es) | Emprendedor |
| Cliente | App móvil |
| Fase del plan | F6 |
| **Estado** | **🟡 Parcial** |

## Descripción

El emprendedor ve los compromisos de los que es responsable y los marca cumplidos.

## Qué se hizo

- `GET /mentoring/commitments/me` filtra por `responsable_usuarioid` del usuario y acepta `estado` (p. ej. `pendiente`).
- Móvil: sección «Compromisos pendientes» en Inicio (`CommitmentsSection`) con casillas que funcionan **sin conexión** (cola local + `POST /mentoring/sync`) y etiqueta «Pendiente de sincronizar».

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/mentoring/repository.py` (`commitments_for_user`), `Backend/EmprendeU/src/emprendeu/modules/mentoring/service.py` (`my_commitments`) |
| Móvil | `Frontend/app_emprendeu/lib/features/mentoring/presentation/widgets/commitments_section.dart`, `data/datasources/mentoring_remote_data_source.dart`, `mentoring_local_data_source.dart` |

## Por qué se hizo así

- El plan pedía reutilizar la pantalla de compromisos que ya existía en la app y ajustarla al nuevo esquema (`responsable_usuarioid`), y así se hizo.

## Verificación

- `Backend/EmprendeU/tests/test_mentoring_api.py::test_recomendaciones_y_compromisos_del_emprendimiento` (cubre compromisos del responsable)
- `Frontend/app_emprendeu/test/features/mentoring/` (repositorio y pantallas)

## Pendiente

- La app pide `commitments/me` sin filtro de estado: lista pendientes y cumplidos juntos, no solo los pendientes.
- No hay prueba de API dedicada al caso ni cierre formal en el tablero del plan (fase 6).
- «Tareas» distintas de compromisos no existen como entidad aparte.
