"use client";

import { Button } from "@/components/ui/button";
import { useRunner } from "@/components/forms/form-bits";

import { deactivateKnowledgeAction } from "../server/actions";

export function DeactivateKnowledgeButton({ id, title }: { id: number; title: string }) {
  const { pending, run } = useRunner();
  return (
    <Button
      type="button"
      variant="outline"
      disabled={pending}
      onClick={() => run(() => deactivateKnowledgeAction(id, title))}
      className="h-11 rounded-xl border-border-strong px-3.5 text-sm font-semibold"
      aria-label={`Desactivar ${title}`}
    >
      Desactivar
    </Button>
  );
}
