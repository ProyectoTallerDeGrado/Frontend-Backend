import type { Metadata } from "next";

import { SessionsScreen } from "@/features/mentoring";

export const metadata: Metadata = { title: "Sesiones · CIE-U" };

const ESTADOS = ["programada", "realizada", "cancelada"];
const DAY = /^\d{4}-\d{2}-\d{2}$/;

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function SessionsPage({ searchParams }: PageProps<"/mentoring/sessions">) {
  const { estado, desde, hasta, page } = await searchParams;
  return (
    <SessionsScreen
      filters={{
        estado: ESTADOS.includes(one(estado)) ? one(estado) : undefined,
        desde: DAY.test(one(desde)) ? one(desde) : undefined,
        hasta: DAY.test(one(hasta)) ? one(hasta) : undefined,
        page: Math.max(1, Number(one(page)) || 1),
      }}
    />
  );
}
