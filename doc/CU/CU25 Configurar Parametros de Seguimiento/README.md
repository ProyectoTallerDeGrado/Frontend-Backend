# CU25 — Configurar Parámetros de Seguimiento

| Campo | Valor |
|---|---|
| Prioridad | Baja |
| Actor(es) | Coordinador y administrador |
| Cliente | Web |
| Fase del plan | F3 |
| **Estado** | **✅ Completado** |

## Descripción

Configurar los umbrales que usan las alertas y los compromisos.

## Qué se hizo

- `GET/PUT /alerts/settings` sobre `parametros_seguimiento` (clave-valor): `dias_inactividad`, `umbral_caida_sentimiento` (25 % se guarda como `-0.25`) y `dias_limite_compromiso`.
- Valida rangos antes de guardar; cada cambio queda en la auditoría.
- Web `/settings/tracking` (`TrackingForm`).

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/alerts/service.py`, `Backend/EmprendeU/src/emprendeu/modules/alerts/repository.py` (`SETTING_KEYS`), `Backend/EmprendeU/src/emprendeu/modules/alerts/router.py` |
| Web | `Frontend/emprendeu/features/alerts/components/tracking-form.tsx`, `Frontend/emprendeu/app/(app)/settings/tracking/page.tsx` |

## Por qué se hizo así

- Los parámetros alimentan el job de alertas (CU13) y el plazo por defecto de los compromisos (CU18), así se ajustan sin desplegar.

## Verificación

- `Backend/EmprendeU/tests/test_alerts_indicators_api.py::test_parametros_se_validan_y_se_auditan`

## Pendiente

- Los valores iniciales (14 días, −20 %, 7 días) eran pregunta abierta del plan: confirmar con el CIE-U.
