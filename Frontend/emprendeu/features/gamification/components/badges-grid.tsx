import { Award } from "lucide-react";

import type { Badge } from "../types";

const COLORS = ["#1F4FD6", "#0A1A44", "#D61F3A", "#0E7A4F", "#7A3FD1", "#B26A00"];

export function BadgesGrid({ badges }: { badges: Badge[] }) {
  return (
    <div className="grid grid-cols-[repeat(auto-fit,minmax(min(240px,100%),1fr))] gap-4">
      {badges.map((b, i) => (
        <div
          key={b.insignia_id}
          className="flex items-start gap-4 rounded-2xl border border-border bg-card p-5"
        >
          <div
            aria-hidden="true"
            className="flex size-[52px] shrink-0 items-center justify-center rounded-[14px] text-white"
            style={{ background: COLORS[i % COLORS.length] }}
          >
            <Award className="size-[26px]" />
          </div>
          <div className="min-w-0">
            <div className="font-heading text-base font-semibold">{b.nombre}</div>
            <div className="mt-1 mb-2.5 text-[13px] leading-snug text-muted-foreground">{b.criterio}</div>
            <span className="inline-block rounded-full bg-danger-tint px-2.5 py-1 text-[13px] font-bold text-danger-foreground">
              +{b.xp_recompensa} XP
            </span>
          </div>
        </div>
      ))}
    </div>
  );
}
