import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { ParticipantsScreen } from "@/features/training";

export const metadata: Metadata = { title: "Participantes · CIE-U" };

export default async function ParticipantsPage({ params }: PageProps<"/training/[id]/participants">) {
  const { id } = await params;
  const trainingId = Number(id);
  if (!Number.isInteger(trainingId) || trainingId <= 0) notFound();
  return <ParticipantsScreen trainingId={trainingId} />;
}
