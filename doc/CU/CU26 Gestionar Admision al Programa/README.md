# CU26 — Gestionar Admisión al Programa

| Campo | Valor |
|---|---|
| Prioridad | Media |
| Actor(es) | Coordinador (y postulante, que envía el formulario) |
| Cliente | Web |
| Fase del plan | F6 |
| **Estado** | **✅ Completado** |

## Descripción

Una persona se postula desde un formulario público; la coordinación revisa las postulaciones pendientes y las admite o rechaza.

## Qué se hizo

- Backend: `POST /admissions` (público, con limitador), `GET /admissions` (pendientes primero), `GET /admissions/{id}` y `POST /admissions/{id}/decision`.
- Al admitir, en **una sola transacción** se crean `usuario`, `emprendedor` y `emprendimiento` y se vincula la postulación; al rechazar se guarda la observación. Una decisión no se puede cambiar.
- Web: formulario público `/apply` y bandeja `/admissions` con su detalle `/admissions/[id]`.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/entrepreneurs/admission_service.py`, `router.py` (`admissions_router`) |
| Web | `Frontend/emprendeu/features/entrepreneurs/components/admissions-screen.tsx`, `admission-detail-screen.tsx`, `apply-view.tsx`; páginas `app/(app)/admissions/` y `app/(public)/apply/` |

## Por qué se hizo así

- La admisión vive en `entrepreneurs` porque crea emprendedores; el alta completa en una transacción evita cuentas a medias.

## Verificación

- `Backend/EmprendeU/tests/test_admissions_api.py`

## Pendiente

- Probar a mano el flujo de punta a punta (postulación → admisión → el emprendedor entra en la app).
