import type { Metadata } from "next";

import { StageHistoryScreen } from "@/features/ventures";

export const metadata: Metadata = { title: "Etapas · CIE-U" };

export default async function VentureStagesPage({ params }: PageProps<"/ventures/[id]/stages">) {
  const { id } = await params;
  return <StageHistoryScreen ventureId={Number(id)} />;
}
