import type { Metadata } from "next";

import { ApplyView } from "@/features/entrepreneurs";

export const metadata: Metadata = { title: "Postula tu emprendimiento · CIE-U" };

export default function ApplyPage() {
  return <ApplyView />;
}
