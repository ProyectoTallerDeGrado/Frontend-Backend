import { create } from "zustand";

export type Toast = { id: number; message: string; tone: "success" | "error"; leaving?: boolean };

type ToastState = {
  toasts: Toast[];
  push: (message: string, tone?: Toast["tone"]) => void;
  dismiss: (id: number) => void;
};

let nextId = 1;

/** Lo que dura la salida (`toast-out` en globals.css); después se quita del árbol. */
const EXIT_MS = 180;
/** Un error se lee con más calma que una confirmación. */
const LIFETIME_MS = { success: 3200, error: 6000 } as const;

/** Avisos transitorios (abajo a la derecha). Estado de UI de cliente, sin lógica de negocio. */
export const useToastStore = create<ToastState>((set, get) => ({
  toasts: [],
  push: (message, tone = "success") => {
    const id = nextId++;
    set((s) => ({ toasts: [...s.toasts, { id, message, tone }] }));
    setTimeout(() => get().dismiss(id), LIFETIME_MS[tone]);
  },
  dismiss: (id) => {
    if (!get().toasts.some((t) => t.id === id && !t.leaving)) return;
    set((s) => ({ toasts: s.toasts.map((t) => (t.id === id ? { ...t, leaving: true } : t)) }));
    setTimeout(() => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })), EXIT_MS);
  },
}));

export const toast = {
  success: (message: string) => useToastStore.getState().push(message, "success"),
  error: (message: string) => useToastStore.getState().push(message, "error"),
};
