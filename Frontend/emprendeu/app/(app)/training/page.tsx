import type { Metadata } from "next";

import { TrainingScreen } from "@/features/training";

export const metadata: Metadata = { title: "Capacitaciones · CIE-U" };

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function TrainingPage({ searchParams }: PageProps<"/training">) {
  const { estado, page } = await searchParams;
  return <TrainingScreen estado={one(estado)} page={Math.max(1, Number(one(page)) || 1)} />;
}
