# CU18 — Registrar Compromisos

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Asesor |
| Cliente | Web (registro); app móvil (cumplimiento) |
| Fase del plan | F2 |
| **Estado** | **✅ Completado** |

## Descripción

El asesor registra compromisos con responsable y fecha límite.

## Qué se hizo

- `POST /mentoring/commitments` y `POST /sessions/{id}/commitments`; estado inicial `pendiente`.
- El responsable debe pertenecer al emprendimiento (emprendedor inscrito o asesor asignado), si no `ResponsibleNotMember`; por defecto es el emprendedor.
- Sin fecha límite se usa `dias_limite_compromiso` de los parámetros (CU25).
- `PATCH /commitments/{id}` marca cumplido o pendiente (el responsable o el personal).
- Web: acción «Compromiso» en `/mentoring/sessions`.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/mentoring/service.py` (`create_commitment`, `register_commitment`, `_update_commitment`) |
| Migración | `db/migrations/versions/f33df1970606_alinear_esquema_con_cieu_schema_completo.py` (`responsable_usuarioid`, `emprendimientoid`, `registrado_por_usuarioid`) |
| Web | `Frontend/emprendeu/features/mentoring/components/session-forms.tsx` |

## Por qué se hizo así

- Se separó «quién registra» de «quién es responsable» para responder la pregunta abierta del plan sobre `usuario_id`.

## Verificación

- `Backend/EmprendeU/tests/test_mentoring_api.py::test_recomendaciones_y_compromisos_del_emprendimiento`, `test_sesion_realizada_compromisos_recomendaciones_e_insignia`

## Pendiente

- Ninguno conocido.
