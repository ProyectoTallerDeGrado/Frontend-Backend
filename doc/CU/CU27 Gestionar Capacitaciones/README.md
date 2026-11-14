# CU27 — Gestionar Capacitaciones

| Campo | Valor |
|---|---|
| Prioridad | Media (propuesta) |
| Actor(es) | Coordinador |
| Cliente | Web |
| Fase del plan | F6 |
| **Estado** | **✅ Completado** |

## Descripción

La coordinación crea, edita y cambia el estado (programada, realizada, cancelada) de las capacitaciones del programa.

## Qué se hizo

- Backend: `GET/POST /training`, `GET /training/{id}` (añadido en esta revisión) y `PATCH /training/{id}`.
- Web: lista `/training` con filtro por estado y paginación, hoja lateral para crear y editar.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/training/` (`router.py`, `service.py`) |
| Web | `Frontend/emprendeu/features/training/` (`training-screen.tsx`, `training-form.tsx`, `server/actions.ts`); página `app/(app)/training/page.tsx` |

## Por qué se hizo así

- No existe un estado «publicada» en el esquema: una capacitación `programada` ya es visible para los emprendedores.

## Verificación

- `Backend/EmprendeU/tests/test_training_documents_api.py`
- Web: `pnpm lint`, `tsc` y `pnpm build` sin errores (la web aún no tiene pruebas automatizadas).

## Pendiente

- Probar a mano en el navegador.
