import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { FollowUpScreen } from "@/features/mentoring";
import { getVenture } from "@/features/ventures";

export const metadata: Metadata = { title: "Seguimiento · CIE-U" };

export default async function VentureFollowUpPage({ params }: PageProps<"/ventures/[id]/follow-up">) {
  const { id } = await params;
  const ventureId = Number(id);
  if (!Number.isInteger(ventureId) || ventureId <= 0) notFound();
  const venture = await getVenture(ventureId);
  return <FollowUpScreen ventureId={ventureId} ventureName={venture.nombre} />;
}
