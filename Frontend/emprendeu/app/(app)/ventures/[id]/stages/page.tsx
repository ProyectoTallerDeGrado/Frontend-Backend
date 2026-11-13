import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { StageHistoryScreen, getVenture } from "@/features/ventures";

export const metadata: Metadata = { title: "Etapas · CIE-U" };

export default async function VentureStagesPage({ params }: PageProps<"/ventures/[id]/stages">) {
  const { id } = await params;
  const ventureId = Number(id);
  if (!Number.isInteger(ventureId) || ventureId <= 0) notFound();
  const venture = await getVenture(ventureId);
  return <StageHistoryScreen ventureId={ventureId} ventureName={venture.nombre} />;
}
