import { create } from "zustand";

import type { HelpMessage } from "../types";

type HelpChatState = {
  /** Usuario al que pertenece la conversación en pantalla (`usuario_id`). */
  ownerId: number | null;
  open: boolean;
  pending: boolean;
  messages: HelpMessage[];
  /** Vincula el chat a un usuario. Si cambió la sesión, descarta la conversación anterior. */
  bind: (userId: number) => void;
  setOpen: (open: boolean) => void;
  add: (message: Omit<HelpMessage, "id">) => void;
  setPending: (pending: boolean) => void;
  clear: () => void;
};

let nextId = 1;

/**
 * Chat de ayuda: se conserva al navegar entre pantallas y se pierde al recargar.
 * Cada conversación es de un solo usuario: al iniciar sesión otra persona en el mismo
 * navegador, `bind` la vacía para que no vea los mensajes de quien estuvo antes.
 */
export const useHelpChatStore = create<HelpChatState>((set) => ({
  ownerId: null,
  open: false,
  pending: false,
  messages: [],
  bind: (userId) =>
    set((s) => (s.ownerId === userId ? s : { ownerId: userId, open: false, pending: false, messages: [] })),
  setOpen: (open) => set({ open }),
  add: (message) => set((s) => ({ messages: [...s.messages, { ...message, id: nextId++ }] })),
  setPending: (pending) => set({ pending }),
  clear: () => set({ messages: [] }),
}));
