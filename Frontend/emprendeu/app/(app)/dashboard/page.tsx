import type { Metadata } from "next";

import { DashboardScreen } from "@/features/indicators";

export const metadata: Metadata = { title: "Dashboard · CIE-U" };

const DAY = /^\d{4}-\d{2}-\d{2}$/;

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function DashboardPage({ searchParams }: PageProps<"/dashboard">) {
  const { desde, hasta, etapa } = await searchParams;
  return (
    <DashboardScreen
      filters={{
        desde: DAY.test(one(desde)) ? one(desde) : undefined,
        hasta: DAY.test(one(hasta)) ? one(hasta) : undefined,
        etapa: Number(one(etapa)) || undefined,
      }}
    />
  );
}
