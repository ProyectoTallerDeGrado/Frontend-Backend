import "server-only";

import { authedFetch } from "@/features/auth";

import { participantSchema, trainingPageSchema, trainingSchema } from "../schemas/training-schemas";

export const TRAINING_PAGE_SIZE = 20;

export async function listTrainings(params: { estado?: string; page?: number }) {
  const search = new URLSearchParams({ page: String(params.page ?? 1), page_size: String(TRAINING_PAGE_SIZE) });
  if (params.estado) search.set("estado", params.estado);
  return trainingPageSchema.parse(await authedFetch(`/training?${search}`));
}

export async function getTraining(id: number) {
  return trainingSchema.parse(await authedFetch(`/training/${id}`));
}

export async function listParticipants(id: number) {
  return participantSchema.array().parse(await authedFetch(`/training/${id}/participants`));
}
