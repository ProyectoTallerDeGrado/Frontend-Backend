import { z } from "zod";

export const knowledgeSchema = z.object({
  documento_conocimiento_id: z.number(),
  titulo: z.string(),
  descripcion: z.string().nullable(),
  fuente: z.string().nullable(),
  /** `procesando` → `activo`, o `error` si el modelo de embeddings no respondió; `inactivo` si se retiró. */
  estado: z.string().nullable(),
  fecha_carga: z.string().nullable(),
  total_fragmentos: z.number(),
});

export const aiStatusSchema = z.object({
  ollama_disponible: z.boolean(),
  documentos_activos: z.number(),
});

/** Un tema que el coach no pudo responder (`GET /ai/knowledge/gaps`). Es anónimo. */
export const knowledgeGapSchema = z.object({
  tema: z.string(),
  veces: z.number(),
  ultima_fecha: z.string(),
  ejemplos: z.array(z.string()),
});

export const knowledgeGapsSchema = z.object({
  desde: z.string(),
  hasta: z.string(),
  /** true: agrupadas por similitud con el modelo de embeddings; false: por texto igual. */
  por_similitud: z.boolean(),
  temas: z.array(knowledgeGapSchema),
});

/** Formatos que el backend sabe leer y tope de tamaño (`MAX_UPLOAD_MB`, 10 por defecto). */
export const KNOWLEDGE_EXTENSIONS = [".txt", ".md", ".pdf", ".docx"] as const;
export const KNOWLEDGE_MAX_MB = 10;

/** Validación en el borde antes de enviar el archivo al backend. */
export function validateKnowledgeFile(file: { name: string; size: number } | null): string | null {
  if (!file || file.size === 0) return "Elige un archivo con contenido.";
  const lower = file.name.toLowerCase();
  if (!KNOWLEDGE_EXTENSIONS.some((ext) => lower.endsWith(ext)))
    return `Usa un archivo ${KNOWLEDGE_EXTENSIONS.join(", ")}.`;
  if (file.size > KNOWLEDGE_MAX_MB * 1024 * 1024) return `El archivo supera ${KNOWLEDGE_MAX_MB} MB.`;
  return null;
}
