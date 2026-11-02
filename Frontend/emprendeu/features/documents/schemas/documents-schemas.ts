import { z } from "zod";

export const documentSchema = z.object({
  documento_id: z.number(),
  nombre: z.string(),
  tipo: z.string().nullable(),
  usuario_id: z.number(),
  emprendimiento_id: z.number().nullable(),
  hito_id: z.number().nullable().optional(),
  fecha_subida: z.string().nullable(),
});

/** Formatos que acepta el backend y tope de tamaño (`MAX_UPLOAD_MB`, 10 por defecto). */
export const DOCUMENT_EXTENSIONS = [".pdf", ".png", ".jpg", ".jpeg", ".webp", ".txt", ".csv", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx"] as const;
export const DOCUMENT_MAX_MB = 10;

export function validateDocumentFile(file: { name: string; size: number } | null): string | null {
  if (!file || file.size === 0) return "Elige un archivo con contenido.";
  const lower = file.name.toLowerCase();
  if (!DOCUMENT_EXTENSIONS.some((ext) => lower.endsWith(ext))) return "Ese tipo de archivo no es válido.";
  if (file.size > DOCUMENT_MAX_MB * 1024 * 1024) return `El archivo supera ${DOCUMENT_MAX_MB} MB.`;
  return null;
}
