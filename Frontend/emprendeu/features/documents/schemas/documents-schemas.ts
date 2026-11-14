import { z } from "zod";

/** Respuesta de `GET /documents` según el OpenAPI del backend. */
export const documentSchema = z.object({
  documento_id: z.number(),
  nombre: z.string(),
  tipo: z.string().nullable(),
  usuario_id: z.number(),
  emprendimiento_id: z.number().nullable(),
  hito_id: z.number().nullable(),
  fecha_subida: z.string().nullable(),
});

/** Extensiones y tope que acepta el backend (`documents/storage.py`). */
export const DOCUMENT_EXTENSIONS = [
  ".pdf", ".png", ".jpg", ".jpeg", ".webp", ".txt", ".csv",
  ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
];
export const DOCUMENT_MAX_MB = 10;

export function validateDocumentFile(file: File | null): string | null {
  if (!file || file.size === 0) return "Elige un archivo.";
  const ext = file.name.slice(file.name.lastIndexOf(".")).toLowerCase();
  if (!DOCUMENT_EXTENSIONS.includes(ext)) return `Formato no permitido. Usa: ${DOCUMENT_EXTENSIONS.join(", ")}.`;
  if (file.size > DOCUMENT_MAX_MB * 1024 * 1024) return `El archivo supera ${DOCUMENT_MAX_MB} MB.`;
  return null;
}
