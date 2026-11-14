import type { z } from "zod";

import type { aiStatusSchema, knowledgeGapsSchema, knowledgeSchema } from "./schemas/ai-schemas";

export type Knowledge = z.infer<typeof knowledgeSchema>;
export type AiStatus = z.infer<typeof aiStatusSchema>;
export type KnowledgeGaps = z.infer<typeof knowledgeGapsSchema>;
export type ActionResult = { ok: boolean; message: string };
