import "server-only";

import { authedFetch } from "@/features/auth";

import {
  needInboxPageSchema,
  stageSchema,
  stepSchema,
  ventureSchema,
  venturePageSchema,
  ventureOptionsSchema,
} from "../schemas/ventures-schemas";
import type { NeedFilters, Stage, StageStep } from "../types";

export const VENTURES_PAGE_SIZE = 20;
export const NEEDS_PAGE_SIZE = 20;

export async function listStages(): Promise<Stage[]> {
  return stageSchema.array().parse(await authedFetch("/stages"));
}

/** Emprendimientos para listas de selección (nombre e id), hasta 100. */
export async function listVentureOptions(): Promise<{ id: number; name: string }[]> {
  const page = ventureOptionsSchema.parse(await authedFetch("/ventures?page=1&page_size=100"));
  return page.items.map((v) => ({ id: v.emprendimiento_id, name: v.nombre }));
}

export async function listVentures(params: { q?: string; estado?: string; page?: number }) {
  const search = new URLSearchParams({
    page: String(params.page ?? 1),
    page_size: String(VENTURES_PAGE_SIZE),
  });
  if (params.q) search.set("q", params.q);
  if (params.estado) search.set("estado", params.estado);
  return venturePageSchema.parse(await authedFetch(`/ventures?${search}`));
}

/** Recorrido del emprendimiento por las etapas (la anterior se conserva al avanzar). */
export async function getStageHistory(ventureId: number): Promise<StageStep[]> {
  return stepSchema.array().parse(await authedFetch(`/ventures/${ventureId}/stages`));
}

export async function getVenture(ventureId: number) {
  return ventureSchema.parse(await authedFetch(`/ventures/${ventureId}`));
}

/** CU24 · Bandeja del personal con las necesidades y dificultades reportadas. */
export async function listNeeds(filters: NeedFilters) {
  const search = new URLSearchParams({ page: String(filters.page ?? 1), page_size: String(NEEDS_PAGE_SIZE) });
  if (filters.estado) search.set("estado", filters.estado);
  if (filters.tipo) search.set("tipo", filters.tipo);
  return needInboxPageSchema.parse(await authedFetch(`/venture-needs?${search}`));
}
