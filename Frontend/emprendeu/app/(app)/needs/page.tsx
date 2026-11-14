import type { Metadata } from "next";

import { NeedsScreen } from "@/features/ventures";

export const metadata: Metadata = { title: "Necesidades · CIE-U" };

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function NeedsPage({ searchParams }: PageProps<"/needs">) {
  const { estado, tipo, page } = await searchParams;
  return (
    <NeedsScreen
      filters={{
        estado: one(estado) === "detectada" || one(estado) === "resuelta" ? (one(estado) as "detectada" | "resuelta") : undefined,
        tipo: one(tipo) === "necesidad" || one(tipo) === "dificultad" ? (one(tipo) as "necesidad" | "dificultad") : undefined,
        page: Math.max(1, Number(one(page)) || 1),
      }}
    />
  );
}
