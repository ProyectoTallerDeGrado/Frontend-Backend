import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { HistoryScreen, parseHistoryFilters } from "@/features/mentoring";
import { getVenture } from "@/features/ventures";

export const metadata: Metadata = { title: "Historial · CIE-U" };

export default async function VentureHistoryPage({
  params,
  searchParams,
}: PageProps<"/ventures/[id]/history">) {
  const { id } = await params;
  const ventureId = Number(id);
  if (!Number.isInteger(ventureId) || ventureId <= 0) notFound();
  const venture = await getVenture(ventureId);
  return (
    <HistoryScreen
      ventureId={ventureId}
      ventureName={venture.nombre}
      filters={parseHistoryFilters(await searchParams)}
    />
  );
}
