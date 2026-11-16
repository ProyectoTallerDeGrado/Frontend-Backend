import type { Metadata } from "next";
import Link from "next/link";

import { StatusScreen, statusAction } from "@/components/layout/status-screen";

export const metadata: Metadata = { title: "Página no encontrada · CIE-U" };

export default function NotFound() {
  return (
    <StatusScreen
      code="Error 404"
      title="Esta página se salió de órbita."
      description="La dirección no existe o cambió de lugar. Vuelve al inicio y sigue desde ahí."
    >
      <Link href="/" className={statusAction.primary}>
        Ir al inicio
      </Link>
      <Link href="/apply" className={statusAction.ghost}>
        Postular mi emprendimiento
      </Link>
    </StatusScreen>
  );
}
