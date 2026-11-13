"use client";

import { LoaderCircle } from "lucide-react";

import { useRunner } from "@/components/forms/form-bits";
import { Button } from "@/components/ui/button";

import { resolveNeedAction } from "../server/actions";

export function ResolveNeedButton({ rowId, name }: { rowId: number; name: string }) {
  const { pending, run } = useRunner();
  return (
    <Button
      type="button"
      variant="outline"
      disabled={pending}
      className="h-10 gap-2 rounded-xl border-border-strong px-3 text-[13px] font-semibold"
      onClick={() => run(() => resolveNeedAction(rowId, name))}
    >
      {pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
      Marcar resuelta
    </Button>
  );
}
