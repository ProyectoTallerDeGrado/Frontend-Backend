import type { Metadata } from "next";

import { VenturesScreen } from "@/features/ventures";

export const metadata: Metadata = { title: "Emprendimientos · CIE-U" };

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function VenturesPage({ searchParams }: PageProps<"/ventures">) {
  const { q, estado, page } = await searchParams;
  return <VenturesScreen q={one(q)} estado={one(estado)} page={Math.max(1, Number(one(page)) || 1)} />;
}
