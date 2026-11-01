import "server-only";

import { authedFetch } from "@/features/auth";

import { overviewSchema } from "../schemas/indicators-schemas";
import type { Overview } from "../types";

export async function getOverview(): Promise<Overview> {
  return overviewSchema.parse(await authedFetch("/indicators/overview"));
}
