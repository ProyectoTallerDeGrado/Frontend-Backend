import type { z } from "zod";

import type { alertSchema, trackingSettingsSchema } from "./schemas/alerts-schemas";

export type TrackingSettings = Omit<z.infer<typeof trackingSettingsSchema>, "fecha_actualizacion">;
export type Alert = z.infer<typeof alertSchema>;
export type ActionResult = { ok: boolean; message: string };
export type AlertFilters = { estado?: string; tipo?: string; page?: number };
