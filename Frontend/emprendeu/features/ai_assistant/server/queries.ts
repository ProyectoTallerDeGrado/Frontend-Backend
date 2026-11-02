import "server-only";

import { authedFetch } from "@/features/auth";

import { aiStatusSchema, knowledgeSchema } from "../schemas/ai-schemas";

export async function listKnowledge() {
  return knowledgeSchema.array().parse(await authedFetch("/ai/knowledge"));
}

export async function getAiStatus() {
  return aiStatusSchema.parse(await authedFetch("/ai/status"));
}
