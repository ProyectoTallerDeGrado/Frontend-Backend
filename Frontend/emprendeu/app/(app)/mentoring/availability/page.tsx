import type { Metadata } from "next";

import { AvailabilityScreen } from "@/features/mentoring";

export const metadata: Metadata = { title: "Mi disponibilidad · CIE-U" };

export default function AvailabilityPage() {
  return <AvailabilityScreen />;
}
