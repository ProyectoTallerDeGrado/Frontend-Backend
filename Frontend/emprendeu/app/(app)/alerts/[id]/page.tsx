import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { AlertDetailScreen } from "@/features/alerts";

export const metadata: Metadata = { title: "Alerta · CIE-U" };

export default async function AlertDetailPage({ params }: PageProps<"/alerts/[id]">) {
  const { id } = await params;
  const alertId = Number(id);
  if (!Number.isInteger(alertId) || alertId <= 0) notFound();
  return <AlertDetailScreen alertId={alertId} />;
}
