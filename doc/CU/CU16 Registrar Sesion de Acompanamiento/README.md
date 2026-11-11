# CU16 — Registrar Sesión de Acompañamiento

| Campo | Valor |
|---|---|
| Prioridad | Alta |
| Actor(es) | Asesor |
| Cliente | Web |
| Fase del plan | F2 |
| **Estado** | **✅ Completado** |

## Descripción

El asesor registra una sesión realizada (fecha, tema, modalidad, observaciones) o completa una agendada.

## Qué se hizo

- `POST /mentoring/sessions/register` registra una sesión ya realizada (no admite fecha futura, `FutureDate`).
- `POST /sessions/{id}/complete` marca como realizada una sesión agendada con sus datos; una sesión cerrada no se edita (`SessionNotEditable`).
- Al completar sesiones se pueden otorgar insignias.
- Web `/mentoring/sessions`: acciones «Registrar sesión» y «Realizada» en hojas laterales.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/mentoring/router.py`, `Backend/EmprendeU/src/emprendeu/modules/mentoring/service.py` |
| Web | `Frontend/emprendeu/features/mentoring/components/sessions-view.tsx`, `session-forms.tsx`, `Frontend/emprendeu/app/(app)/mentoring/sessions/page.tsx` |

## Por qué se hizo así

- Solo sobre sesiones realizadas, como pide el caso de uso: el registro es evidencia del acompañamiento.

## Verificación

- `Backend/EmprendeU/tests/test_mentoring_api.py::test_registrar_sesion_realizada`, `test_completar_sesion_agendada_con_datos`, `test_sesion_realizada_compromisos_recomendaciones_e_insignia`

## Pendiente

- Ninguno conocido.
