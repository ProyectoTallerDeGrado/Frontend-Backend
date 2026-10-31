import "server-only";

import { authedFetch } from "@/features/auth";

import { stageSchema } from "../schemas/ventures-schemas";
import type { Stage } from "../types";

export async function listStages(): Promise<Stage[]> {
  return stageSchema.array().parse(await authedFetch("/stages"));
}
