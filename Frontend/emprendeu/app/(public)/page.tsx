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
    images: [{ url: "/brand/cie-u-logo.png", alt: "Logo del CIE-U" }],
  },
  twitter: { card: "summary", title, description, images: ["/brand/cie-u-logo.png"] },
};

export default async function LandingPage() {
  const session = await getSession();
  return <LandingView signedIn={Boolean(session)} />;
}
