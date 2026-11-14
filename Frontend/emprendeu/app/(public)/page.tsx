import type { Metadata } from "next";

import { getSession } from "@/features/auth";
import { LandingView } from "@/features/landing";

export const metadata: Metadata = {
  title: "CIE-U · Emprende desde la universidad",
  description:
    "El Centro de Innovación y Emprendimiento Universitario de la FCEE · UAGRM acompaña a estudiantes que emprenden: mentorías, retos, coach IA y capacitaciones.",
};

export default async function LandingPage() {
  const session = await getSession();
  return <LandingView signedIn={Boolean(session)} />;
}
