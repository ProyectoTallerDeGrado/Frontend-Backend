import type { Metadata } from "next";

import { AlertsScreen } from "@/features/alerts";

export const metadata: Metadata = { title: "Alertas · CIE-U" };

const ESTADOS = ["abierta", "revisada", "atendida", "descartada"];
const TIPOS = ["inactividad", "sentimiento", "compromiso_vencido"];

function one(value: string | string[] | undefined): string {
  return typeof value === "string" ? value : "";
}

export default async function AlertsPage({ searchParams }: PageProps<"/alerts">) {
  const { estado, tipo, page } = await searchParams;
  return (
    <AlertsScreen
      filters={{
        estado: ESTADOS.includes(one(estado)) ? one(estado) : undefined,
        tipo: TIPOS.includes(one(tipo)) ? one(tipo) : undefined,
        page: Math.max(1, Number(one(page)) || 1),
      }}
    />
  );
}
