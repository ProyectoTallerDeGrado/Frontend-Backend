import type { z } from "zod";

import type {
  assignmentSchema,
  availabilitySchema,
  commitmentSchema,
  historyEventSchema,
  mentorSchema,
  participantSchema,
  progressSummarySchema,
  recommendationSchema,
  sessionSchema,
} from "./schemas/mentoring-schemas";

export type Mentor = z.infer<typeof mentorSchema>;
export type Assignment = z.infer<typeof assignmentSchema>;
export type Availability = z.infer<typeof availabilitySchema>;
export type Participant = z.infer<typeof participantSchema>;
export type Session = z.infer<typeof sessionSchema>;

export type Recommendation = z.infer<typeof recommendationSchema>;
export type Commitment = z.infer<typeof commitmentSchema>;
/** Compromiso con el cálculo de si ya venció (se resuelve en el servidor, no al renderizar). */
export type VentureCommitment = Commitment & { vencido: boolean };
export type ProgressSummary = z.infer<typeof progressSummarySchema>;

export type HistoryEvent = z.infer<typeof historyEventSchema>;
export type HistoryKind = HistoryEvent["tipo"];

/** Filtros del historial (viajan en la URL): orden, tipos de evento y periodo. */
export type HistoryFilters = {
  orden: "asc" | "desc";
  tipos: HistoryKind[];
  desde?: string;
  hasta?: string;
};
export type ActionResult = { ok: boolean; message: string };

/** Filtros de la lista de sesiones (viajan en la URL). */
export type SessionFilters = { estado?: string; desde?: string; hasta?: string; page?: number };

/** Emprendimiento para las listas de selección. */
export type VentureOption = { id: number; name: string };

