import { create } from "zustand";

import type { HelpMessage } from "../types";

type HelpChatState = {
  open: boolean;
  pending: boolean;
  messages: HelpMessage[];
  setOpen: (open: boolean) => void;
  add: (message: Omit<HelpMessage, "id">) => void;
  setPending: (pending: boolean) => void;
  clear: () => void;
};

let nextId = 1;

/** Chat de ayuda: se conserva al navegar entre pantallas y se pierde al recargar. */
export const useHelpChatStore = create<HelpChatState>((set) => ({
  open: false,
  pending: false,
  messages: [],
  setOpen: (open) => set({ open }),
  add: (message) => set((s) => ({ messages: [...s.messages, { ...message, id: nextId++ }] })),
  setPending: (pending) => set({ pending }),
  clear: () => set({ messages: [] }),
}));
