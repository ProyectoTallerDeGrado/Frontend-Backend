import "server-only";

import { authedFetch } from "@/features/auth";

import { aiStatusSchema, knowledgeGapsSchema, knowledgeSchema } from "../schemas/ai-schemas";

export async function listKnowledge() {
  return knowledgeSchema.array().parse(await authedFetch("/ai/knowledge"));
}

export async function getAiStatus() {
  return aiStatusSchema.parse(await authedFetch("/ai/status"));
}

/** Preguntas sin respuesta de los últimos 90 días (el backend fija la ventana). */
export async function getKnowledgeGaps() {
  return knowledgeGapsSchema.parse(await authedFetch("/ai/knowledge/gaps"));
}
