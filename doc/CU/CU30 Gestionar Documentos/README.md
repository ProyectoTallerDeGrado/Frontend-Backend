# CU30 — Gestionar Documentos

| Campo | Valor |
|---|---|
| Prioridad | Media (propuesta) |
| Actor(es) | Coordinador y asesor (web); emprendedor (app) |
| Cliente | Web y app móvil |
| Fase del plan | F6 |
| **Estado** | **🟡 Parcial (app sin descarga)** |

## Descripción

Subir, descargar y eliminar los documentos de un emprendimiento; el emprendedor solo ve los de su emprendimiento.

## Qué se hizo

- Backend: `POST /documents` (multipart), `GET /documents`, `GET /documents/{id}/download` y `DELETE /documents/{id}`, con lista blanca de extensiones, tope de tamaño y auditoría.
- Web: `/ventures/[id]/documents` (enlace «Documentos» en la lista de emprendimientos) con subir, descargar (ruta `.../download` que reenvía el archivo con la sesión) y eliminar.
- Móvil: Perfil → «Documentos» (`/venture/documents`) lista todos los archivos del emprendimiento, permite subir y eliminar los propios.

## Dónde está implementado

| Capa | Archivos |
|---|---|
| Backend | `Backend/EmprendeU/src/emprendeu/modules/documents/` |
| Web | `Frontend/emprendeu/features/documents/`; páginas `app/(app)/ventures/[id]/documents/` y su `route.ts` de descarga |
| Móvil | `Frontend/app_emprendeu/lib/features/documents/presentation/screens/documents_screen.dart` |

## Por qué se hizo así

- Solo quien subió el archivo (o el personal con `emprendedores:modificacion`) lo elimina; la app oculta el botón en los ajenos.

## Verificación

- `Backend/EmprendeU/tests/test_training_documents_api.py`
- `Frontend/app_emprendeu/test/features/documents/documents_screen_test.dart`

## Pendiente

- **Descargar desde la app móvil:** hace falta un paquete para guardar y abrir el archivo (p. ej. `path_provider` + `open_filex`), porque el endpoint exige el token y no se puede abrir con una URL. No se agregó para no sumar dependencias nativas sin probar en dispositivo.
- Probar a mano la subida y descarga en la web.
