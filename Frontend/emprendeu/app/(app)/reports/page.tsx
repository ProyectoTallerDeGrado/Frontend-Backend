import type { Metadata } from "next";

import { REPORT_KINDS, ReportsScreen, type ReportKind } from "@/features/indicators";

export const metadata: Metadata = { title: "Reportes · CIE-U" };

const DAY = /^\d{4}-\d{2}-\d{2}$/;

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function ReportsPage({ searchParams }: PageProps<"/reports">) {
  const { kind, desde, hasta, etapa } = await searchParams;
  const selected = (REPORT_KINDS as readonly string[]).includes(one(kind)) ? (one(kind) as ReportKind) : "resumen";
  return (
    <ReportsScreen
      kind={selected}
      filters={{
        desde: DAY.test(one(desde)) ? one(desde) : undefined,
        hasta: DAY.test(one(hasta)) ? one(hasta) : undefined,
        etapa: Number(one(etapa)) || undefined,
      }}
    />
  );
}
