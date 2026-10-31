import "server-only";

import { authedFetch } from "@/features/auth";

import { badgeSchema, challengeSchema } from "../schemas/gamification-schemas";
import type { Badge, Challenge } from "../types";

export async function listChallenges(): Promise<Challenge[]> {
  return challengeSchema.array().parse(await authedFetch("/challenges"));
}

export async function listBadges(): Promise<Badge[]> {
  return badgeSchema.array().parse(await authedFetch("/badges"));
}
