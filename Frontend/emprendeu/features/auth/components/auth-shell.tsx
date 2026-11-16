import type { ReactNode } from "react";

import { BrandPanel } from "./brand-panel";

type AuthShellProps = {
  title: string;
  subtitle: string;
  children: ReactNode;
};

/** Pantalla dividida: marca a la izquierda, formulario a la derecha. */
export function AuthShell({ title, subtitle, children }: AuthShellProps) {
  return (
    <div className="flex min-h-screen flex-wrap">
      <BrandPanel />
      <main className="flex min-w-0 flex-[1_1_480px] items-center justify-center px-8 py-12">
        <div className="w-full max-w-[420px]">
          <h2 className="mb-2 font-heading text-[28px] font-bold tracking-[-.01em] text-foreground">
            {title}
          </h2>
          <p className="mb-8 text-base leading-normal text-muted-foreground">
            {subtitle}
          </p>
          {children}
        </div>
      </main>
    </div>
  );
}
