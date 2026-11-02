import type { z } from "zod";

import type {
  assignmentSchema,
  availabilitySchema,
  historyEventSchema,
  mentorSchema,
  participantSchema,
  sessionSchema,
} from "./schemas/mentoring-schemas";

export type Mentor = z.infer<typeof mentorSchema>;
export type Assignment = z.infer<typeof assignmentSchema>;
export type Availability = z.infer<typeof availabilitySchema>;
export type Participant = z.infer<typeof participantSchema>;
export type Session = z.infer<typeof sessionSchema>;

export type HistoryEvent = z.infer<typeof historyEventSchema>;
export type ActionResult = { ok: boolean; message: string };

/** Filtros de la lista de sesiones (viajan en la URL). */
export type SessionFilters = { estado?: string; desde?: string; hasta?: string; page?: number };

/** Emprendimiento para las listas de selección. */
export type VentureOption = { id: number; name: string };
