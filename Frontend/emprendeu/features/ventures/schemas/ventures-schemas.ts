import { z } from "zod";

export const stageSchema = z.object({
  etapa_id: z.number(),
  nombre: z.string(),
  descripcion: z.string().nullable(),
  criterios: z.string().nullable(),
  orden: z.number().nullable(),
  estado: z.string().nullable(),
});

/** Página de `GET /ventures` (solo lo que usan las listas de selección). */
export const ventureOptionsSchema = z.object({
  items: z.array(z.object({ emprendimiento_id: z.number(), nombre: z.string() })),
});

/** Rol dentro del equipo del emprendimiento (lo valida el backend). */
export const MEMBER_ROLES = ["fundador", "cofundador", "miembro"] as const;
export type MemberRole = (typeof MEMBER_ROLES)[number];

export const memberSchema = z.object({
  emprendedor_id: z.number(),
  usuario_id: z.number(),
  nombre: z.string().nullable(),
  apellido: z.string().nullable(),
  email: z.string().nullable(),
  rol_en_emprendimiento: z.string().nullable(),
  fecha_ingreso: z.string().nullable(),
});

export const ventureSchema = z.object({
  emprendimiento_id: z.number(),
  nombre: z.string(),
  descripcion: z.string().nullable(),
  sector: z.string().nullable(),
  estado: z.string().nullable(),
  fecha_creacion: z.string().nullable(),
  etapa_actual: stageSchema.nullable(),
  integrantes: z.array(memberSchema).default([]),
});

export const venturePageSchema = z.object({
  items: z.array(ventureSchema),
  page: z.number(),
  page_size: z.number(),
  total: z.number(),
});

export const stepSchema = z.object({
  emprendimiento_etapa_id: z.number(),
  etapa_id: z.number(),
  etapa: z.string(),
  estado: z.string().nullable(),
  fecha_inicio: z.string().nullable(),
  fecha_fin: z.string().nullable(),
  observaciones: z.string().nullable(),
});

export const VENTURE_STATES = ["activo", "pausado", "cerrado"] as const;

/** Formulario de emprendimiento (alta y edición por la coordinación). */
export const ventureFormSchema = z.object({
  name: z.string().trim().min(1, "Ingresa el nombre del emprendimiento.").max(160, "Máximo 160 caracteres."),
  description: z.string().trim(),
  sector: z.string().trim().max(120, "Máximo 120 caracteres."),
  estado: z.string().trim().max(40),
});

/** Equipo inicial al crear: uno o más emprendedores distintos, cada uno con su rol. */
export const teamSchema = z
  .array(z.object({ entrepreneurId: z.number().int().positive(), role: z.enum(MEMBER_ROLES) }))
  .min(1, "Agrega al menos un emprendedor al equipo.")
  .max(20, "Máximo 20 integrantes.")
  .refine((team) => new Set(team.map((m) => m.entrepreneurId)).size === team.length, {
    message: "Un emprendedor aparece dos veces en el equipo.",
  });
