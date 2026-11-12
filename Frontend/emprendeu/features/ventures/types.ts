import type { z } from "zod";

import type { memberSchema, stageSchema, stepSchema, ventureSchema } from "./schemas/ventures-schemas";

export type Stage = z.infer<typeof stageSchema>;
export type Venture = z.infer<typeof ventureSchema>;
/** Integrante del equipo de un emprendimiento. */
export type VentureMember = z.infer<typeof memberSchema>;
export type { MemberRole } from "./schemas/ventures-schemas";
/** Un paso del recorrido de un emprendimiento por las etapas. */
export type StageStep = z.infer<typeof stepSchema>;
