"use client";

import { useOptimistic, useTransition } from "react";
import { Minus, Plus } from "lucide-react";

import { toast } from "@/components/layout/toast-store";

import { updateChallengeEvidenceAction, updateChallengeXpAction } from "../server/actions";
import type { Challenge } from "../types";

const COLS = "grid-cols-[minmax(260px,2fr)_170px_190px_150px]";
const STEP = 10;

export function ChallengesTable({ challenges, canEdit }: { challenges: Challenge[]; canEdit: boolean }) {
  const [, startTransition] = useTransition();
  const [xpRows, setXp] = useOptimistic(challenges, (state, change: { id: number; xp: number }) =>
    state.map((c) => (c.reto_id === change.id ? { ...c, xp_recompensa: change.xp } : c)),
  );
  const [rows, setEvidence] = useOptimistic(xpRows, (state, change: { id: number; value: boolean }) =>
    state.map((c) => (c.reto_id === change.id ? { ...c, requiere_evidencia: change.value } : c)),
  );

  const toggleEvidence = (c: Challenge) =>
    startTransition(async () => {
      const next = !c.requiere_evidencia;
      setEvidence({ id: c.reto_id, value: next });
      const result = await updateChallengeEvidenceAction(c.reto_id, next);
      if (!result.ok) toast.error(result.message);
    });

  const change = (c: Challenge, delta: number) =>
    startTransition(async () => {
      const xp = Math.max(0, c.xp_recompensa + delta);
      setXp({ id: c.reto_id, xp });
      const result = await updateChallengeXpAction(c.reto_id, xp);
      if (!result.ok) toast.error(result.message);
    });

  const btn =
    "flex size-11 items-center justify-center rounded-[10px] bg-[#f4f6fb] outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30 disabled:opacity-50";

  return (
    <>
      <div className="overflow-x-auto overflow-y-hidden rounded-2xl border border-border bg-card">
        <div className="min-w-[740px]">
          <div
            className={`grid ${COLS} gap-4 border-b border-border bg-[#f8fafe] px-6 py-3.5 text-[13px] font-bold tracking-[.04em] text-muted-foreground uppercase`}
          >
            <span>Reto</span>
            <span>Etapa</span>
            <span>Recompensa (XP)</span>
            <span>Evidencia</span>
          </div>
          {rows.map((c, i) => (
            <div
              key={c.reto_id}
              className={`grid ${COLS} animate-[fade-up_.45s_ease_both] items-center gap-4 border-b border-[#eef2fa] px-6 py-2.5 transition-colors hover:bg-[#f4f7ff]`}
              style={{ animationDelay: `${i * 50}ms` }}
            >
              <span className="text-[15px] font-semibold">{c.titulo}</span>
              <span>
                <span className="inline-block rounded-full bg-blue-50 px-3 py-1 text-[13px] font-bold text-[#12308a]">
                  {c.etapa}
                </span>
              </span>
              <div className="flex items-center gap-1">
                <button
                  type="button"
                  aria-label={`Reducir XP de ${c.titulo}`}
                  disabled={!canEdit || c.xp_recompensa <= 0}
                  onClick={() => change(c, -STEP)}
                  className={btn}
                >
                  <Minus aria-hidden="true" className="size-4" strokeWidth={2.6} />
                </button>
                <span className="min-w-[52px] text-center font-heading text-[17px] font-bold" aria-live="polite">
                  {c.xp_recompensa}
                </span>
                <button
                  type="button"
                  aria-label={`Aumentar XP de ${c.titulo}`}
                  disabled={!canEdit}
                  onClick={() => change(c, STEP)}
                  className={btn}
                >
                  <Plus aria-hidden="true" className="size-4" strokeWidth={2.6} />
                </button>
              </div>
              <label className="flex items-center gap-2 text-[14px] font-semibold">
                <input
                  type="checkbox"
                  checked={c.requiere_evidencia}
                  disabled={!canEdit}
                  onChange={() => toggleEvidence(c)}
                  className="size-5"
                />
                Obligatoria
              </label>
            </div>
          ))}
        </div>
      </div>
      <p className="mt-4 text-[13px] text-muted-foreground">
        El XP solo se asigna una vez por reto cumplido; el sistema no duplica recompensas.
      </p>
    </>
  );
}
