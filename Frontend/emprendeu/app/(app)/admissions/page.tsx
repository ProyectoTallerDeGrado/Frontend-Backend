import type { Metadata } from "next";

import { AdmissionsScreen } from "@/features/entrepreneurs";

export const metadata: Metadata = { title: "Admisiones · CIE-U" };

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function AdmissionsPage({ searchParams }: PageProps<"/admissions">) {
  const { estado, q, page } = await searchParams;
  const state = one(estado);
  return (
    <AdmissionsScreen
      filters={{
        estado: state === "pendiente" || state === "admitida" || state === "rechazada" ? state : undefined,
        q: one(q) || undefined,
        page: Math.max(1, Number(one(page)) || 1),
      }}
    />
  );
}
