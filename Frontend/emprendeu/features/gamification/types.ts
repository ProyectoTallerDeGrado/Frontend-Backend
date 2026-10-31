import type { z } from "zod";

import type { badgeSchema, challengeSchema } from "./schemas/gamification-schemas";

export type Challenge = z.infer<typeof challengeSchema>;
export type Badge = z.infer<typeof badgeSchema>;
