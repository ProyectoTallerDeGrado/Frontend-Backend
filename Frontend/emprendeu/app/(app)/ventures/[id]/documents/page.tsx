import type { Metadata } from "next";

import { DocumentsScreen } from "@/features/documents";

export const metadata: Metadata = { title: "Documentos · CIE-U" };

export default async function VentureDocumentsPage({ params }: PageProps<"/ventures/[id]/documents">) {
  const { id } = await params;
  return <DocumentsScreen ventureId={Number(id)} />;
}
