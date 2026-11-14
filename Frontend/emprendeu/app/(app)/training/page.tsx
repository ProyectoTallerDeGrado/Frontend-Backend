import type { Metadata } from "next";

import { TrainingScreen } from "@/features/training";

export const metadata: Metadata = { title: "Capacitaciones · CIE-U" };

const ESTADOS = ["programada", "realizada", "cancelada"];

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function TrainingPage({ searchParams }: PageProps<"/training">) {
  const { estado, page } = await searchParams;
  return (
    <TrainingScreen
      filters={{
        estado: ESTADOS.includes(one(estado)) ? one(estado) : undefined,
        page: Math.max(1, Number(one(page)) || 1),
      }}
    />
  );
}
