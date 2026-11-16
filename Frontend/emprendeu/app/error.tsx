"use client";

import Link from "next/link";
import { useEffect } from "react";

import { StatusScreen, statusAction } from "@/components/layout/status-screen";

export default function RootError({ error, retry }: { error: Error & { digest?: string }; retry: () => void }) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <StatusScreen
      code="Algo falló"
      title="No pudimos cargar esta página."
      description="Puede ser un problema pasajero del servidor. Intenta de nuevo; si sigue igual, vuelve en unos minutos."
    >
      <button type="button" onClick={() => retry()} className={statusAction.primary}>
        Intentar de nuevo
      </button>
      <Link href="/" className={statusAction.ghost}>
        Ir al inicio
      </Link>
    </StatusScreen>
  );
}
