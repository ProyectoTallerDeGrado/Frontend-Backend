import type { z } from "zod";

import type { badgeSchema, challengeSchema, journeySchema } from "./schemas/gamification-schemas";

export type Challenge = z.infer<typeof challengeSchema>;
export type Badge = z.infer<typeof badgeSchema>;

export type Journey = z.infer<typeof journeySchema>;
