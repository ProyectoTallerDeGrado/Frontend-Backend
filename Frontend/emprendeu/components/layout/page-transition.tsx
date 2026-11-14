"use client";

import { usePathname } from "next/navigation";
import { ViewTransition, type ReactNode } from "react";

/**
 * Fundido entre secciones: al cambiar la ruta React anima el contenido viejo y el nuevo
 * (clase `.page` en globals.css). Las pestañas de la ficha del emprendimiento cuentan como
 * la misma sección para que la cabecera no parpadee.
 */
export function PageTransition({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const key = pathname.replace(/^(\/ventures\/\d+)\/.*/, "$1");
  return (
    <ViewTransition key={key} name="page" share="page" enter="page" default="none">
      <div>{children}</div>
    </ViewTransition>
  );
}
