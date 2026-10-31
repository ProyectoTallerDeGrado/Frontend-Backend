import type { z } from "zod";

import type { trackingSettingsSchema } from "./schemas/alerts-schemas";

export type TrackingSettings = Omit<z.infer<typeof trackingSettingsSchema>, "fecha_actualizacion">;
export type ActionResult = { ok: boolean; message: string };
