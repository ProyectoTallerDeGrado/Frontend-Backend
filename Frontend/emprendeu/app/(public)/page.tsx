import type { Metadata } from "next";

import { getSession } from "@/features/auth";
import { LandingView } from "@/features/landing";
import { env } from "@/lib/env";

const title = "CIE-U · Emprende desde la universidad";
const description =
  "El Centro de Innovación y Emprendimiento Universitario de la FCEE · UAGRM acompaña a estudiantes que emprenden: mentorías, retos, coach IA y capacitaciones. Gratis.";

export const metadata: Metadata = {
  metadataBase: new URL(env.siteUrl),
  title,
  description,
  openGraph: {
    type: "website",
    locale: "es_BO",
    siteName: "CIE-U",
    title,
    description,
    url: "/",
  },
  // La imagen sale de `app/opengraph-image.tsx` (1200 × 630).
  twitter: { card: "summary_large_image", title, description },
};

export default async function LandingPage() {
  // La portada no depende del backend: si no responde, se muestra como a un visitante sin sesión.
  const session = await getSession().catch(() => null);
  return <LandingView signedIn={Boolean(session)} />;
}
