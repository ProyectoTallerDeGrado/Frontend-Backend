import type { Metadata } from "next";

import { EntrepreneursScreen } from "@/features/entrepreneurs";

export const metadata: Metadata = { title: "Emprendedores · CIE-U" };

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function EntrepreneursPage({ searchParams }: PageProps<"/entrepreneurs">) {
  const { q, page } = await searchParams;
  return <EntrepreneursScreen q={one(q)} page={Math.max(1, Number(one(page)) || 1)} />;
}
