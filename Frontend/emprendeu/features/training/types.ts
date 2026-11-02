import type { z } from "zod";

import type { participantSchema, trainingSchema } from "./schemas/training-schemas";

export type Training = z.infer<typeof trainingSchema>;
export type Participant = z.infer<typeof participantSchema>;
export type ActionResult = { ok: boolean; message: string };
