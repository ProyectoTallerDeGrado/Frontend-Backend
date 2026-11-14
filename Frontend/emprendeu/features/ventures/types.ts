import type { z } from "zod";

import type {
  memberSchema,
  needInboxItemSchema,
  stageSchema,
  stepSchema,
  ventureSchema,
} from "./schemas/ventures-schemas";

export type Stage = z.infer<typeof stageSchema>;
/** Necesidad o dificultad reportada por un emprendimiento (CU24). */
export type NeedItem = z.infer<typeof needInboxItemSchema>;
/** Filtros de la bandeja de necesidades (viajan en la URL). */
export type NeedFilters = { estado?: "detectada" | "resuelta"; tipo?: "necesidad" | "dificultad"; page?: number };
export type Venture = z.infer<typeof ventureSchema>;
/** Integrante del equipo de un emprendimiento. */
export type VentureMember = z.infer<typeof memberSchema>;
export type { MemberRole } from "./schemas/ventures-schemas";
/** Un paso del recorrido de un emprendimiento por las etapas. */
export type StageStep = z.infer<typeof stepSchema>;
