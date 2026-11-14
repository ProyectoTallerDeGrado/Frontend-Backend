import type { z } from "zod";

import type { participantSchema, trainingSchema, trainingInputSchema } from "./schemas/training-schemas";

export type Training = z.infer<typeof trainingSchema>;
export type Participant = z.infer<typeof participantSchema>;
export type TrainingInput = z.input<typeof trainingInputSchema>;
export type { ActionResult } from "@/components/forms/form-bits";

/** Filtros de la lista (viajan en la URL). */
export type TrainingFilters = { estado?: string; page?: number };
