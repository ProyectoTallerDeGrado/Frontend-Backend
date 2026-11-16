import { PageSkeleton } from "@/components/data/skeleton";

/** Esqueleto mientras carga una página del panel (los datos se leen en el servidor). */
export default function PanelLoading() {
  return <PageSkeleton />;
}
