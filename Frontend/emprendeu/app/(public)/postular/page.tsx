import type { Metadata } from "next";

import { ApplicationView } from "@/features/entrepreneurs";

export const metadata: Metadata = { title: "Postúlate · CIE-U" };

export default function ApplyPage() {
  return <ApplicationView />;
}
