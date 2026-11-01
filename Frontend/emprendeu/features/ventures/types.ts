import type { z } from "zod";

import type { stageSchema } from "./schemas/ventures-schemas";

export type Stage = z.infer<typeof stageSchema>;
