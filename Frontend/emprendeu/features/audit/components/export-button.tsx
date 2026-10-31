import { Download } from "lucide-react";

import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

/** Descarga el CSV (ruta `/audit/export`) respetando el filtro actual. */
export function ExportAuditButton({ categoria }: { categoria: string }) {
  const href = categoria ? `/audit/export?categoria=${encodeURIComponent(categoria)}` : "/audit/export";
  return (
    <a
      href={href}
      download
      className={cn(
        buttonVariants({ variant: "outline" }),
        "h-12 gap-2 rounded-xl border-[1.5px] border-border-strong px-[18px] text-[15px] font-semibold",
      )}
    >
      <Download aria-hidden="true" className="size-[18px]" />
      Exportar CSV
    </a>
  );
}
