import type { z } from "zod";

import type { documentSchema } from "./schemas/documents-schemas";

export type VentureDocument = z.infer<typeof documentSchema>;
export type { ActionResult } from "@/components/forms/form-bits";
