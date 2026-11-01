import Link from "next/link";

import { formatWhen } from "@/lib/format";

import type { AuditEntry } from "../types";

export function RecentActivity({ entries }: { entries: AuditEntry[] }) {
  return (
    <section className="rounded-2xl border border-border bg-card p-6">
      <div className="mb-2 flex items-center justify-between">
        <h2 className="font-heading text-lg font-semibold">Actividad reciente</h2>
        <Link
          href="/audit"
          className="inline-flex min-h-11 items-center rounded-xl border-[1.5px] border-border-strong px-4 text-sm font-semibold outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30"
        >
          Ver auditoría
        </Link>
      </div>
      {entries.length === 0 && <p className="py-4 text-sm text-muted-foreground">Aún no hay actividad registrada.</p>}
      {entries.map((a) => (
        <div key={a.bitacora_id} className="flex flex-wrap items-center gap-x-4 gap-y-1.5 border-t border-[#eef2fa] py-3.5">
          <span className="w-24 shrink-0 text-[13px] text-muted-foreground">{formatWhen(a.fecha)}</span>
          <span className="min-w-[260px] flex-1 text-[15px]">
            <strong>{a.actor ?? "Sistema"}</strong> · {a.descripcion}
            {a.objeto && <span className="text-muted-foreground"> · {a.objeto}</span>}
          </span>
        </div>
      ))}
    </section>
  );
}
