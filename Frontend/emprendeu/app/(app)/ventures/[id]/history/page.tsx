import type { Metadata } from "next";

import { HistoryScreen, parseHistoryFilters } from "@/features/mentoring";

export const metadata: Metadata = { title: "Historial · CIE-U" };

export default async function VentureHistoryPage({ params, searchParams }: PageProps<"/ventures/[id]/history">) {
  const { id } = await params;
  return <HistoryScreen ventureId={Number(id)} filters={parseHistoryFilters(await searchParams)} />;
}
