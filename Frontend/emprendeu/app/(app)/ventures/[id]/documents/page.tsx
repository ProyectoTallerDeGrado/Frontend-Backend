import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { DocumentsScreen } from "@/features/documents";
import { getVenture } from "@/features/ventures";

export const metadata: Metadata = { title: "Documentos · CIE-U" };

export default async function VentureDocumentsPage({ params }: PageProps<"/ventures/[id]/documents">) {
  const { id } = await params;
  const ventureId = Number(id);
  if (!Number.isInteger(ventureId) || ventureId <= 0) notFound();
  const venture = await getVenture(ventureId);
  return <DocumentsScreen ventureId={ventureId} ventureName={venture.nombre} />;
}
