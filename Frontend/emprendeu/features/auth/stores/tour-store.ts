import { create } from "zustand";

type TourState = {
  open: boolean;
  step: number;
  start: () => void;
  close: () => void;
  go: (step: number) => void;
};

/** Tutorial guiado: lo abre el layout en el primer ingreso o el botón «Ver tutorial». */
export const useTourStore = create<TourState>((set) => ({
  open: false,
  step: 0,
  start: () => set({ open: true, step: 0 }),
  close: () => set({ open: false }),
  go: (step) => set({ step }),
}));
