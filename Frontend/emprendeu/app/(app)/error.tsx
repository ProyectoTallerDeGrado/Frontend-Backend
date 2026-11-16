"use client";

import { TriangleAlert } from "lucide-react";
import { useEffect } from "react";

import { EmptyState } from "@/components/data/empty-state";
import { Button } from "@/components/ui/button";

/** Error dentro del panel: el menú sigue en pantalla y solo falla el contenido. */
export default function PanelError({ error, retry }: { error: Error & { digest?: string }; retry: () => void }) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <EmptyState
      icon={TriangleAlert}
      title="No pudimos cargar esta sección"
      description="Puede ser un problema pasajero del servidor. Intenta de nuevo; si sigue igual, vuelve en unos minutos."
      action={
        <Button type="button" size="lg" onClick={() => retry()}>
          Intentar de nuevo
        </Button>
      }
    />
  );
}
