# CU20 — Registrar Avances e Hitos

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Emprendedor |
| Cliente | App móvil |
| Fase del plan | F4 |
| **Estado** | **✅ Completado** |

## Descripción

El emprendedor registra avances e hitos, con evidencia opcional, y los marca cumplidos.

## Qué se hizo

- Hitos: `GET/POST /ventures/{id}/milestones`, `PATCH /milestones/{id}`.
- Evidencia: `POST /documents` multipart con `hito_id` (columna `documentos.hitoid`); valida tipo y tamaño de archivo.
- Avances: `POST/GET /mentoring/progress`, idempotentes por `referencia_cliente`, y `POST /mentoring/sync` para la cola sin conexión.
- Móvil: pantalla «Hitos y evidencia» (`/venture/milestones`) y sección de avances en Inicio; si el hito se guarda pero la evidencia falla, el hito se conserva y se avisa.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/ventures/service.py` (hitos), `Backend/EmprendeU/src/emprendeu/modules/documents/` (evidencia, `storage.py`), `Backend/EmprendeU/src/emprendeu/modules/mentoring/service.py` (avances y sync) |
| Móvil | `Frontend/app_emprendeu/lib/features/ventures/presentation/screens/milestones_screen.dart`, `Frontend/app_emprendeu/lib/features/documents/`, `Frontend/app_emprendeu/lib/features/mentoring/presentation/widgets/progress_section.dart`, `data/datasources/mentoring_local_data_source.dart` |

## Por qué se hizo así

- Cola sin conexión para avances: el emprendedor puede registrar en campo sin red; `referencia_cliente` evita duplicados al reenviar.
- Hito y evidencia en dos pasos para no perder el hito si falla la subida.

## Verificación

- `Backend/EmprendeU/tests/test_entrepreneurs_api.py::test_cu20_hito_con_evidencia`, `Backend/EmprendeU/tests/test_mentoring_api.py::test_avances_idempotentes_y_sincronizacion`, `Backend/EmprendeU/tests/test_training_documents_api.py` (tipos y tamaño)
- `Frontend/app_emprendeu/test/features/ventures/ventures_screens_test.dart` (tres casos CU20), `Frontend/app_emprendeu/test/features/mentoring/data/mentoring_repository_test.dart`

## Pendiente

- Ninguno conocido.
