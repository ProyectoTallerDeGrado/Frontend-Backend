"use client";

import { Button } from "@/components/ui/button";
import { useRunner } from "@/components/forms/form-bits";

import { setTrainingStateAction } from "../server/actions";

type Target = "publicada" | "realizada" | "cancelada";

const NEXT: Record<string, { target: Target; label: string; primary?: boolean }[]> = {
  borrador: [
    { target: "publicada", label: "Publicar", primary: true },
    { target: "cancelada", label: "Cancelar" },
  ],
  publicada: [
    { target: "realizada", label: "Marcar realizada", primary: true },
    { target: "cancelada", label: "Cancelar" },
  ],
};

/** Acciones de estado según el estado actual (borrador, publicada); las demás no tienen salida. */
export function TrainingStateButtons({ id, title, estado }: { id: number; title: string; estado: string | null }) {
  const { pending, run } = useRunner();
  const actions = NEXT[estado ?? ""] ?? [];
  return (
    <>
      {actions.map((a) => (
        <Button
          key={a.target}
          type="button"
          variant={a.primary ? "default" : "outline"}
          disabled={pending}
          onClick={() => run(() => setTrainingStateAction(id, a.target, title))}
          className={`h-11 rounded-xl px-3.5 text-sm font-semibold ${a.primary ? "" : "border-border-strong"}`}
          aria-label={`${a.label}: ${title}`}
        >
          {a.label}
        </Button>
      ))}
    </>
  );
}
