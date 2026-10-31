"use client";

import { useTransition } from "react";

import { toast } from "@/components/layout/toast-store";
import { ToggleSwitch } from "@/components/ui/toggle-switch";

import { setStageStateAction } from "../server/actions";
import type { Stage } from "../types";

type Props = {
  stages: Stage[];
  /** Cantidad de retos por `etapa_id` (la aporta quien compone la página). */
  challengeCounts: Record<number, number>;
  canEdit: boolean;
};

function StageRow({ stage, count, canEdit, index }: { stage: Stage; count: number; canEdit: boolean; index: number }) {
  const [pending, startTransition] = useTransition();
  const on = stage.estado === "activa";
  return (
    <div
      className="flex animate-[fade-up_.45s_ease_both] items-center gap-[18px] border-b border-[#eef2fa] py-4 transition-colors last:border-b-0 hover:bg-[#f4f7ff]"
      style={{ animationDelay: `${index * 70}ms` }}
    >
      <div
        aria-hidden="true"
        className="flex size-10 shrink-0 items-center justify-center rounded-full bg-blue-50 font-heading font-bold text-primary"
      >
        {stage.orden}
      </div>
      <div className="min-w-0 flex-1">
        <div className="text-base font-semibold">{stage.nombre}</div>
        <div className="text-[13px] text-muted-foreground">{count} retos asociados</div>
      </div>
      <span className={`text-sm font-semibold ${on ? "text-success-foreground" : "text-muted-foreground"}`}>
        {on ? "Activa" : "Inactiva"}
      </span>
      <ToggleSwitch
        label={`Etapa ${stage.nombre}`}
        checked={on}
        disabled={!canEdit || pending}
        onCheckedChange={(next) =>
          startTransition(async () => {
            const result = await setStageStateAction(stage.etapa_id, next ? "activa" : "inactiva", stage.nombre);
            if (result.ok) toast.success(result.message);
            else toast.error(result.message);
          })
        }
      />
    </div>
  );
}

export function StageList({ stages, challengeCounts, canEdit }: Props) {
  return (
    <div className="rounded-2xl border border-border bg-card px-6 py-2">
      {stages.map((s, i) => (
        <StageRow key={s.etapa_id} stage={s} count={challengeCounts[s.etapa_id] ?? 0} canEdit={canEdit} index={i} />
      ))}
    </div>
  );
}
