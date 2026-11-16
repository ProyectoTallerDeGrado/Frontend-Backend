import { PageSkeleton } from "@/components/data/skeleton";

/** La cabecera de la ficha la pinta el layout: aquí solo carga la pestaña. */
export default function VentureTabLoading() {
  return <PageSkeleton variant="section" />;
}
