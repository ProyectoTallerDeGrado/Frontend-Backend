import type { Metadata } from "next";

import { FollowUpScreen } from "@/features/mentoring";

export const metadata: Metadata = { title: "Seguimiento · CIE-U" };

export default async function VentureFollowUpPage({ params }: PageProps<"/ventures/[id]/follow-up">) {
  const { id } = await params;
  return <FollowUpScreen ventureId={Number(id)} />;
}
