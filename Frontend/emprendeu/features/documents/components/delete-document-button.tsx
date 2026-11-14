"use client";

import { LoaderCircle, Trash2 } from "lucide-react";

import { useRunner } from "@/components/forms/form-bits";
import { Button } from "@/components/ui/button";

import { deleteDocumentAction } from "../server/actions";

export function DeleteDocumentButton({ ventureId, documentId, name }: { ventureId: number; documentId: number; name: string }) {
  const { pending, run } = useRunner();
  return (
    <Button
      type="button"
      variant="outline"
      disabled={pending}
      aria-label={`Eliminar ${name}`}
      className="size-11 rounded-xl border-border-strong"
      onClick={() => {
        if (window.confirm(`¿Eliminar «${name}»? No se puede deshacer.`)) run(() => deleteDocumentAction(ventureId, documentId, name));
      }}
    >
      {pending ? <LoaderCircle aria-hidden="true" className="size-4 animate-spin" /> : <Trash2 aria-hidden="true" className="size-4" />}
    </Button>
  );
}
