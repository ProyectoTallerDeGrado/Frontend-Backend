import "server-only";

import { authedFetch } from "@/features/auth";

import { badgeSchema, challengeSchema, journeySchema } from "../schemas/gamification-schemas";
import type { Badge, Challenge, Journey } from "../types";

export async function listChallenges(): Promise<Challenge[]> {
  return challengeSchema.array().parse(await authedFetch("/challenges"));
}

export async function listBadges(): Promise<Badge[]> {
  return badgeSchema.array().parse(await authedFetch("/badges"));
}

/** CU06: camino del emprendimiento (etapas y retos); el personal puede ver el de cualquiera. */
export async function getJourney(ventureId: number): Promise<Journey> {
  return journeySchema.parse(await authedFetch(`/journey?emprendimiento_id=${ventureId}`));
}
