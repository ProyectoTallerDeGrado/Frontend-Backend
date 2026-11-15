import "server-only";

import { authedFetch } from "@/features/auth";

import { ApiError } from "@/lib/api-client";

import { admissionPageSchema, admissionSchema, entrepreneurPageSchema } from "../schemas/entrepreneurs-schemas";
import type { Admission, AdmissionFilters } from "../types";

export const ENTREPRENEURS_PAGE_SIZE = 20;
export const ADMISSIONS_PAGE_SIZE = 20;

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

/** Búsqueda de emprendedores por nombre, correo o documento (hasta 15 resultados). */
export async function searchEntrepreneurOptions(q: string): Promise<{ id: number; name: string }[]> {
  const page = await listEntrepreneurs({ q: q.trim() || undefined, page: 1 });
  return page.items.slice(0, 15).map((e) => ({
    id: e.emprendedor_id,
    name: `${e.nombre ?? ""} ${e.apellido ?? ""}`.trim() + (e.documento_identidad ? ` · ${e.documento_identidad}` : ""),
  }));
}

/** CU26 · Postulaciones al programa; las pendientes aparecen primero. */
export async function listAdmissions(filters: AdmissionFilters) {
  const search = new URLSearchParams({ page: String(filters.page ?? 1), page_size: String(ADMISSIONS_PAGE_SIZE) });
  if (filters.estado) search.set("estado", filters.estado);
  if (filters.q) search.set("q", filters.q);
  return admissionPageSchema.parse(await authedFetch(`/admissions?${search}`));
}

export async function getAdmission(id: number): Promise<Admission | null> {
  try {
    return admissionSchema.parse(await authedFetch(`/admissions/${id}`));
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) return null;
    throw error;
  }
}
