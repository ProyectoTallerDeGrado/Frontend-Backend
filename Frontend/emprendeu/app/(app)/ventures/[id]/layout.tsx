import { notFound } from "next/navigation";

import { VentureHeader } from "@/features/ventures";

/** Ficha de un emprendimiento: cabecera y pestañas comunes a todas sus secciones. */
export default async function VentureLayout({ children, params }: LayoutProps<"/ventures/[id]">) {
  const { id } = await params;
  const ventureId = Number(id);
  if (!Number.isInteger(ventureId) || ventureId <= 0) notFound();
  return (
    <>
      <VentureHeader ventureId={ventureId} />
      {children}
    </>
  );
}
