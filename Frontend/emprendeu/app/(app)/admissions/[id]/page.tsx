import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { AdmissionDetailScreen } from "@/features/entrepreneurs";

export const metadata: Metadata = { title: "Postulación · CIE-U" };

export default async function AdmissionDetailPage({ params }: PageProps<"/admissions/[id]">) {
  const { id } = await params;
  const admissionId = Number(id);
  if (!Number.isInteger(admissionId) || admissionId <= 0) notFound();
  return <AdmissionDetailScreen id={admissionId} />;
}
