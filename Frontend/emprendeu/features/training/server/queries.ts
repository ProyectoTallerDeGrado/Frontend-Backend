import "server-only";

import { authedFetch } from "@/features/auth";
import { ApiError } from "@/lib/api-client";

import { participantSchema, trainingPageSchema, trainingSchema } from "../schemas/training-schemas";
import type { Participant, Training, TrainingFilters } from "../types";

export const TRAINING_PAGE_SIZE = 20;

/** CU27 · Capacitaciones, paginadas y con filtro por estado. */
export async function listTrainings(filters: TrainingFilters) {
  const search = new URLSearchParams({ page: String(filters.page ?? 1), page_size: String(TRAINING_PAGE_SIZE) });
  if (filters.estado) search.set("estado", filters.estado);
  return trainingPageSchema.parse(await authedFetch(`/training?${search}`));
}

export async function getTraining(id: number): Promise<Training | null> {
  try {
    return trainingSchema.parse(await authedFetch(`/training/${id}`));
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) return null;
    throw error;
  }
}

/** CU28 · Participantes y su asistencia (`null` = aún sin registrar). */
export async function listParticipants(id: number): Promise<Participant[]> {
  return participantSchema.array().parse(await authedFetch(`/training/${id}/participants`));
}
