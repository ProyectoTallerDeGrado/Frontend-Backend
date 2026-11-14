import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { TrainingDetailScreen } from "@/features/training";

export const metadata: Metadata = { title: "Capacitación · CIE-U" };

export default async function TrainingDetailPage({ params }: PageProps<"/training/[id]">) {
  const id = Number((await params).id);
  if (!Number.isInteger(id) || id <= 0) notFound();
  return <TrainingDetailScreen id={id} />;
}
