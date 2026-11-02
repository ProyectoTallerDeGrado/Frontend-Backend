import type { z } from "zod";

import type { stageSchema, stepSchema, ventureSchema } from "./schemas/ventures-schemas";

export type Stage = z.infer<typeof stageSchema>;
export type Venture = z.infer<typeof ventureSchema>;
/** Un paso del recorrido de un emprendimiento por las etapas. */
export type StageStep = z.infer<typeof stepSchema>;
