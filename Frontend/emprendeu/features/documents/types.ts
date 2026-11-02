import type { z } from "zod";

import type { documentSchema } from "./schemas/documents-schemas";

export type Document = z.infer<typeof documentSchema>;
export type ActionResult = { ok: boolean; message: string };
