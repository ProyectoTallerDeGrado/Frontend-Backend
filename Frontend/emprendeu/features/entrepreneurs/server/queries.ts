import "server-only";

import { authedFetch } from "@/features/auth";

import { applicationPageSchema, entrepreneurPageSchema } from "../schemas/entrepreneurs-schemas";

export const ENTREPRENEURS_PAGE_SIZE = 20;

export async function listEntrepreneurs(params: { q?: string; page?: number }) {
  const search = new URLSearchParams({
    page: String(params.page ?? 1),
    page_size: String(ENTREPRENEURS_PAGE_SIZE),
  });
  if (params.q) search.set("q", params.q);
  return entrepreneurPageSchema.parse(await authedFetch(`/entrepreneurs?${search}`));
}

/** Emprendedores para listas de selección (hasta 100), con su documento para distinguir homónimos. */
export async function listEntrepreneurOptions(): Promise<{ id: number; name: string }[]> {
  const page = entrepreneurPageSchema.parse(await authedFetch("/entrepreneurs?page=1&page_size=100"));
  return page.items.map((e) => ({
    id: e.emprendedor_id,
    name: `${e.nombre ?? ""} ${e.apellido ?? ""}`.trim() + (e.documento_identidad ? ` · ${e.documento_identidad}` : ""),
  }));
}

export const APPLICATIONS_PAGE_SIZE = 20;

export async function listApplications(params: { estado?: string; q?: string; page?: number }) {
  const search = new URLSearchParams({
    page: String(params.page ?? 1),
    page_size: String(APPLICATIONS_PAGE_SIZE),
  });
  if (params.estado) search.set("estado", params.estado);
  if (params.q) search.set("q", params.q);
  return applicationPageSchema.parse(await authedFetch(`/applications?${search}`));
}
