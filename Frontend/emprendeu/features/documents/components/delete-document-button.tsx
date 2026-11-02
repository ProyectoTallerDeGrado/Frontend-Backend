"use client";

import { Button } from "@/components/ui/button";
import { useRunner } from "@/components/forms/form-bits";

import { deleteDocumentAction } from "../server/actions";

export function DeleteDocumentButton({ id, name }: { id: number; name: string }) {
  const { pending, run } = useRunner();
  return (
    <Button
      type="button"
      variant="outline"
      disabled={pending}
      onClick={() => {
        if (window.confirm(`¿Eliminar «${name}»? No se puede deshacer.`)) run(() => deleteDocumentAction(id, name));
      }}
      className="h-11 rounded-xl border-border-strong px-3.5 text-sm font-semibold"
      aria-label={`Eliminar ${name}`}
    >
      Eliminar
    </Button>
  );
}
