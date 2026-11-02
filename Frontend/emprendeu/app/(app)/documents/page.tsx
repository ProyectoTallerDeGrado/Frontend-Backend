import type { Metadata } from "next";

import { DocumentsScreen } from "@/features/documents";

export const metadata: Metadata = { title: "Documentos · CIE-U" };

export default async function DocumentsPage({ searchParams }: PageProps<"/documents">) {
  const { emprendimiento_id: ventureId } = await searchParams;
  const id = Number(typeof ventureId === "string" ? ventureId : "");
  return <DocumentsScreen ventureId={Number.isInteger(id) && id > 0 ? id : null} />;
}
