import type { z } from "zod";

import type { entrepreneurSchema } from "./schemas/entrepreneurs-schemas";

export type Entrepreneur = z.infer<typeof entrepreneurSchema>;

/** Resultado de registrar un emprendedor; la clave temporal se muestra una sola vez. */
export type RegisterResult = { ok: boolean; message: string; temporaryPassword?: string | null; fieldErrors?: Record<string, string> };
