import type { z } from "zod";

import type { auditEntrySchema } from "./schemas/audit-schemas";

export type AuditEntry = z.infer<typeof auditEntrySchema>;

export const AUDIT_FILTERS = [
  { key: "", label: "Todos" },
  { key: "usuarios", label: "Usuarios" },
  { key: "roles", label: "Roles" },
  { key: "config", label: "Configuración" },
  { key: "accesos", label: "Accesos" },
  { key: "negocio", label: "Negocio" },
] as const;
