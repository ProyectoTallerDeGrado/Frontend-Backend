import type { z } from "zod";

import type { admissionDecidedSchema, admissionSchema, entrepreneurSchema } from "./schemas/entrepreneurs-schemas";

export type Entrepreneur = z.infer<typeof entrepreneurSchema>;

/** Resultado de registrar un emprendedor; la clave temporal se muestra una sola vez. */
export type RegisterResult = { ok: boolean; message: string; temporaryPassword?: string | null; fieldErrors?: Record<string, string> };

export type Admission = z.infer<typeof admissionSchema>;
export type AdmissionDecided = z.infer<typeof admissionDecidedSchema>;
/** Filtros de la bandeja de postulaciones (viajan en la URL). */
export type AdmissionFilters = { estado?: Admission["estado"]; q?: string; page?: number };

export type ApplyResult = { ok: boolean; message: string; fieldErrors?: Record<string, string> };
export type DecisionResult = { ok: boolean; message: string; temporaryPassword?: string | null };
