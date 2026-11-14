"use client";

import { Check, X } from "lucide-react";

import { useToastStore } from "./toast-store";

export function Toaster() {
  const toasts = useToastStore((s) => s.toasts);
  return (
    <div className="pointer-events-none fixed right-7 bottom-7 z-[80] flex flex-col gap-3">
      {toasts.map((t) => (
        <div
          key={t.id}
          role={t.tone === "error" ? "alert" : "status"}
          className="pointer-events-auto flex max-w-[420px] animate-[fade-up_.35s_cubic-bezier(.2,.8,.2,1)_both] items-center gap-3 rounded-[14px] bg-navy-900 px-[18px] py-3.5 text-sm leading-snug text-white shadow-[0_18px_40px_-12px_rgba(2,31,80,.6)]"
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
          <span>{t.message}</span>
        </div>
      ))}
    </div>
  );
}
