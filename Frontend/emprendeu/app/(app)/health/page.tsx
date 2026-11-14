import type { Metadata } from "next";

import { HealthScreen } from "@/features/indicators";

export const metadata: Metadata = { title: "Salud de emprendimientos · CIE-U" };

export default function HealthPage() {
  return <HealthScreen />;
}
