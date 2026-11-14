"use client";

import { LoaderCircle } from "lucide-react";

import { useRunner } from "@/components/forms/form-bits";
import { Button } from "@/components/ui/button";

import { setCommitmentDoneAction } from "../server/actions";

export function CompleteCommitmentButton({
  commitmentId,
  ventureId,
  done,
}: {
  commitmentId: number;
  ventureId: number;
  done: boolean;
}) {
  const { pending, run } = useRunner();
  return (
    <Button
      type="button"
      variant="outline"
      disabled={pending}
      className="h-10 gap-2 rounded-xl border-border-strong px-3 text-[13px] font-semibold"
      onClick={() => run(() => setCommitmentDoneAction(commitmentId, ventureId, !done))}
    >
      {pending && <LoaderCircle aria-hidden="true" className="size-4 animate-spin" />}
      {done ? "Reabrir" : "Marcar cumplido"}
    </Button>
  );
}
