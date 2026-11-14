import type { z } from "zod";

import type {
  REPORT_KINDS,
  dashboardSchema,
  healthReportSchema,
  overviewSchema,
  reportSchema,
  ventureHealthSchema,
} from "./schemas/indicators-schemas";

export type Overview = z.infer<typeof overviewSchema>;
export type Dashboard = z.infer<typeof dashboardSchema>;
export type Report = z.infer<typeof reportSchema>;
export type HealthReport = z.infer<typeof healthReportSchema>;
export type VentureHealth = z.infer<typeof ventureHealthSchema>;
export type ReportKind = (typeof REPORT_KINDS)[number];

/** Filtros de periodo y etapa (viajan en la URL). */
export type PeriodFilters = { desde?: string; hasta?: string; etapa?: number };
