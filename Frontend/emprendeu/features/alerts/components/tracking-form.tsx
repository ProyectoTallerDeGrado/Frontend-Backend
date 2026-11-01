"use client";

import { useState, useTransition } from "react";
import { Check, LoaderCircle, Minus, Play, Plus } from "lucide-react";

import { toast } from "@/components/layout/toast-store";
import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { ToggleSwitch } from "@/components/ui/toggle-switch";

import { evaluateAlertsAction, saveTrackingSettingsAction } from "../server/actions";
import type { TrackingSettings } from "../types";

type Props = { initial: TrackingSettings; canEdit: boolean; canEvaluate: boolean };

const ALERT_ROWS: { key: keyof Pick<TrackingSettings, "notificar_coordinador" | "notificar_asesor" | "alertar_incumplimiento">; title: string; hint: string }[] = [
  { key: "notificar_coordinador", title: "Notificar al Coordinador del CIE-U", hint: "Alerta con el emprendimiento y la condición detectada." },
  { key: "notificar_asesor", title: "Notificar al asesor asignado", hint: "Permite una intervención oportuna." },
  { key: "alertar_incumplimiento", title: "Incumplimiento de compromisos", hint: "Genera alerta cuando vence un compromiso sin avance." },
];

const card = "rounded-2xl border border-border bg-card p-6 transition-shadow hover:shadow-[0_14px_30px_-18px_rgba(10,26,68,.35)]";

export function TrackingForm({ initial, canEdit, canEvaluate }: Props) {
  const [saved, setSaved] = useState(initial);
  const [draft, setDraft] = useState(initial);
  const [pending, startTransition] = useTransition();
  const [evaluating, startEvaluate] = useTransition();
  const dirty = JSON.stringify(saved) !== JSON.stringify(draft);
  const set = <K extends keyof TrackingSettings>(key: K, value: TrackingSettings[K]) =>
    setDraft((d) => ({ ...d, [key]: value }));

  const apply = () =>
    startTransition(async () => {
      const result = await saveTrackingSettingsAction(draft);
      if (result.ok) {
        setSaved(draft);
        toast.success(result.message);
      } else {
        toast.error(result.message);
      }
    });

  const evaluate = () =>
    startEvaluate(async () => {
      const result = await evaluateAlertsAction();
      if (result.ok) toast.success(result.message);
      else toast.error(result.message);
    });

  const stepper = "flex size-11 items-center justify-center rounded-[10px] bg-[#f4f6fb] outline-none hover:bg-blue-50 focus-visible:ring-3 focus-visible:ring-primary/30 disabled:opacity-50";

  return (
    <div className="flex flex-wrap items-start gap-6">
      <div className="flex min-w-0 flex-[1_1_520px] flex-col gap-5">
        <section className={card}>
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="mb-1 font-heading text-lg font-semibold">Periodo de inactividad</h2>
              <p className="max-w-[460px] text-sm leading-normal text-muted-foreground">
                Los emprendedores sin actividad relevante durante este periodo se marcan para seguimiento. No se
                suspende ni elimina ninguna cuenta.
              </p>
            </div>
            <div className="font-heading text-[34px] font-bold tracking-[-.02em] whitespace-nowrap text-primary">
              {draft.inactividad_dias}
              <span className="text-[15px] font-semibold text-muted-foreground"> días</span>
            </div>
          </div>
          <div className="mt-3 flex h-11 items-center">
            <Slider
              min={3}
              max={30}
              step={1}
              value={[draft.inactividad_dias]}
              disabled={!canEdit}
              thumbLabel="Días de inactividad"
              onValueChange={(v) => set("inactividad_dias", Array.isArray(v) ? v[0] : v)}
            />
          </div>
          <div className="flex justify-between text-[13px] text-muted-foreground">
            <span>3 días</span>
            <span>30 días</span>
          </div>
        </section>

        <section className={card}>
          <h2 className="mb-1 font-heading text-lg font-semibold">Caída del índice de sentimiento</h2>
          <p className="mb-[18px] max-w-[520px] text-sm leading-normal text-muted-foreground">
            Señal complementaria para detectar cambios negativos persistentes. No constituye un diagnóstico y solo es
            visible para personal autorizado.
          </p>
          <div className="flex items-baseline justify-between">
            <span className="text-sm font-semibold">Variación negativa mínima</span>
            <span className="font-heading text-[22px] font-bold text-primary">{draft.caida_sentimiento_pct} %</span>
          </div>
          <div className="flex h-11 items-center">
            <Slider
              min={10}
              max={60}
              step={5}
              value={[draft.caida_sentimiento_pct]}
              disabled={!canEdit}
              thumbLabel="Variación negativa mínima"
              onValueChange={(v) => set("caida_sentimiento_pct", Array.isArray(v) ? v[0] : v)}
            />
          </div>
          <div className="mt-2.5 flex flex-wrap items-center justify-between gap-3">
            <span className="text-sm font-semibold">Periodos consecutivos para activar</span>
            <div className="flex items-center gap-1.5 rounded-xl border-[1.5px] border-border-strong p-0.5">
              <button
                type="button"
                aria-label="Reducir periodos"
                disabled={!canEdit || draft.periodos_consecutivos <= 1}
                onClick={() => set("periodos_consecutivos", draft.periodos_consecutivos - 1)}
                className={stepper}
              >
                <Minus aria-hidden="true" className="size-[18px]" strokeWidth={2.4} />
              </button>
              <span className="min-w-9 text-center text-lg font-bold" aria-live="polite">
                {draft.periodos_consecutivos}
              </span>
              <button
                type="button"
                aria-label="Aumentar periodos"
                disabled={!canEdit || draft.periodos_consecutivos >= 4}
                onClick={() => set("periodos_consecutivos", draft.periodos_consecutivos + 1)}
                className={stepper}
              >
                <Plus aria-hidden="true" className="size-[18px]" strokeWidth={2.4} />
              </button>
            </div>
          </div>
        </section>

        <section className={card}>
          <h2 className="mb-1 font-heading text-lg font-semibold">Alertas por riesgo de deserción</h2>
          <p className="mb-2 text-sm leading-normal text-muted-foreground">
            Una alerta no modifica automáticamente el estado del emprendimiento.
          </p>
          {ALERT_ROWS.map((row) => (
            <div key={row.key} className="flex items-center gap-4 border-t border-[#eef2fa] py-3">
              <div className="min-w-0 flex-1">
                <div className="text-[15px] font-semibold">{row.title}</div>
                <div className="text-[13px] text-muted-foreground">{row.hint}</div>
              </div>
              <ToggleSwitch
                label={row.title}
                checked={draft[row.key]}
                disabled={!canEdit}
                onCheckedChange={(next) => set(row.key, next)}
              />
            </div>
          ))}
        </section>
      </div>

      <aside className="flex min-w-[280px] flex-[0_1_340px] animate-[fade-up_.5s_.1s_ease_both] flex-col gap-[18px] rounded-2xl bg-navy-900 p-6 text-white">
        <div>
          <div className="text-[13px] font-bold tracking-[.06em] text-[#9fb4ee] uppercase">
            Configuración que se aplicará
          </div>
          <div className="mt-1.5 text-sm text-on-navy-muted">Revisa los valores antes de confirmar.</div>
        </div>
        <dl className="flex flex-col gap-3">
          {[
            ["Inactividad", `${draft.inactividad_dias} días`],
            ["Caída de sentimiento", `≥ ${draft.caida_sentimiento_pct} %`],
            ["Periodos consecutivos", String(draft.periodos_consecutivos)],
            [
              "Alertas activas",
              `${[draft.notificar_coordinador, draft.notificar_asesor, draft.alertar_incumplimiento].filter(Boolean).length} de 3`,
            ],
          ].map(([k, v]) => (
            <div key={k} className="flex justify-between gap-3 border-b border-white/[.12] pb-3 text-sm">
              <dt className="text-on-navy-muted">{k}</dt>
              <dd className="text-right font-bold">{v}</dd>
            </div>
          ))}
        </dl>
        {!dirty ? (
          <div role="status" className="flex items-center gap-3 rounded-xl bg-[#0e7a4f]/30 p-3.5 text-sm leading-snug">
            <Check aria-hidden="true" className="size-[22px] shrink-0 text-[#7fe0b0]" strokeWidth={2.6} />
            Esta configuración está aplicada y registrada en la auditoría.
          </div>
        ) : (
          <Button
            type="button"
            disabled={!canEdit || pending}
            onClick={apply}
            className="h-[50px] gap-2 rounded-xl bg-accent-bright text-[15px] font-bold text-[#2a0008] hover:bg-accent-bright/90"
          >
            {pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
            Confirmar y aplicar
          </Button>
        )}
        {canEvaluate && (
          <Button
            type="button"
            variant="ghost"
            disabled={evaluating || dirty}
            onClick={evaluate}
            className="h-11 gap-2 rounded-xl border border-white/25 text-sm font-semibold text-white hover:bg-white/10 hover:text-white"
          >
            {evaluating ? (
              <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />
            ) : (
              <Play aria-hidden="true" className="size-4" />
            )}
            Evaluar alertas ahora
          </Button>
        )}
      </aside>
    </div>
  );
}
