import type { z } from "zod";

import type { overviewSchema } from "./schemas/indicators-schemas";

export type Overview = z.infer<typeof overviewSchema>;
