import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { JourneyScreen } from "@/features/gamification";
import { getVenture } from "@/features/ventures";

export const metadata: Metadata = { title: "Progreso · CIE-U" };

export default async function VentureProgressPage({ params }: PageProps<"/ventures/[id]/progress">) {
  const { id } = await params;
  const ventureId = Number(id);
  if (!Number.isInteger(ventureId) || ventureId <= 0) notFound();
  const venture = await getVenture(ventureId);
  return <JourneyScreen ventureId={ventureId} ventureName={venture.nombre} />;
}
