import type { Metadata } from "next";

import { KnowledgeScreen } from "@/features/ai_assistant";

export const metadata: Metadata = { title: "Base de conocimiento · CIE-U" };

export default function KnowledgePage() {
  return <KnowledgeScreen />;
}
