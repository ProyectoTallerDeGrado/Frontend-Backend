import "server-only";

import { authedFetch } from "@/features/auth";

import { documentSchema } from "../schemas/documents-schemas";

export async function listDocuments(ventureId?: number) {
  const search = ventureId ? `?emprendimiento_id=${ventureId}` : "";
  return documentSchema.array().parse(await authedFetch(`/documents${search}`));
}
