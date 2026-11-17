"use client";

import { Check, X } from "lucide-react";

import { useToastStore } from "./toast-store";

export function Toaster() {
  const toasts = useToastStore((s) => s.toasts);
  const dismiss = useToastStore((s) => s.dismiss);
  return (
    <div className="pointer-events-none fixed inset-x-4 bottom-22 z-[80] flex flex-col items-end gap-3 sm:inset-x-auto sm:right-7 sm:bottom-24">
      {toasts.map((t) => (
        <div
          key={t.id}
          role={t.tone === "error" ? "alert" : "status"}
          className={`pointer-events-auto flex w-full max-w-[420px] items-center gap-3 rounded-[14px] bg-navy-900 py-2 pr-2 pl-[18px] text-sm leading-snug text-white shadow-overlay sm:w-auto ${
            t.leaving
              ? "animate-[toast-out_.18s_cubic-bezier(.4,0,1,1)_both]"
              : "animate-[toast-in_.35s_cubic-bezier(.2,.8,.2,1)_both]"
          }`}
        >
          <span
            className={`flex size-[26px] shrink-0 items-center justify-center rounded-full ${t.tone === "error" ? "bg-destructive" : "bg-success"}`}
          >
            {t.tone === "error" ? (
              <X aria-hidden="true" className="size-3.5" strokeWidth={3} />
            ) : (
              <Check aria-hidden="true" className="size-3.5" strokeWidth={3} />
            )}
          </span>
          <span className="min-w-0 flex-1 py-1.5">{t.message}</span>
          <button
            type="button"
            onClick={() => dismiss(t.id)}
            aria-label="Cerrar aviso"
            className="flex size-11 shrink-0 items-center justify-center rounded-lg text-on-navy-muted outline-none transition-colors hover:bg-white/10 hover:text-white focus-visible:ring-3 focus-visible:ring-white/50"
          >
            <X aria-hidden="true" className="size-4" />
          </button>
        </div>
      ))}
    </div>
  );
}
