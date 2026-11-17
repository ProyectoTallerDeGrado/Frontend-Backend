import type { z } from "zod";

import type { aiStatusSchema, helpReplySchema, knowledgeGapsSchema, knowledgeSchema } from "./schemas/ai-schemas";

export type Knowledge = z.infer<typeof knowledgeSchema>;
export type AiStatus = z.infer<typeof aiStatusSchema>;
export type KnowledgeGaps = z.infer<typeof knowledgeGapsSchema>;
export type ActionResult = { ok: boolean; message: string };
export type HelpReply = z.infer<typeof helpReplySchema>;
/** Un mensaje del chat de ayuda (vive solo en el navegador; el backend no lo guarda). */
export type HelpMessage = { id: number; role: "user" | "assistant"; text: string; origin?: HelpReply["origen"] };
export type HelpResult = { ok: true; reply: HelpReply } | { ok: false; message: string };
