import { redirect } from "next/navigation";

import { hasPermission, requireSession } from "@/features/auth";
import { ventureHref } from "@/features/ventures";

/** `/ventures/{id}` abre la primera pestaña de la ficha que el usuario puede ver. */
export default async function VenturePage({ params }: PageProps<"/ventures/[id]">) {
  const { id } = await params;
  const user = await requireSession();
  redirect(ventureHref(Number(id), hasPermission(user, "seguimiento:consulta")));
}
