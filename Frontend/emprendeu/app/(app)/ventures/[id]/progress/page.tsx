import type { Metadata } from "next";

import { JourneyScreen } from "@/features/gamification";

export const metadata: Metadata = { title: "Progreso · CIE-U" };

export default async function VentureProgressPage({ params }: PageProps<"/ventures/[id]/progress">) {
  const { id } = await params;
  return <JourneyScreen ventureId={Number(id)} />;
}
