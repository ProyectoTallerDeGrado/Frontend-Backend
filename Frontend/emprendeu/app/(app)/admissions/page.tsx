import type { Metadata } from "next";

import { AdmissionsScreen } from "@/features/entrepreneurs";

export const metadata: Metadata = { title: "Admisión · CIE-U" };

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function AdmissionsPage({ searchParams }: PageProps<"/admissions">) {
  const { estado, q, page } = await searchParams;
  return <AdmissionsScreen estado={one(estado)} q={one(q)} page={Math.max(1, Number(one(page)) || 1)} />;
}
