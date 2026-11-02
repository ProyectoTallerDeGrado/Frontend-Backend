import type { z } from "zod";

import type { REPORT_KINDS, dashboardSchema, overviewSchema, reportSchema } from "./schemas/indicators-schemas";

export type Overview = z.infer<typeof overviewSchema>;
export type Dashboard = z.infer<typeof dashboardSchema>;
export type Report = z.infer<typeof reportSchema>;
export type ReportKind = (typeof REPORT_KINDS)[number];

/** Filtros de periodo y etapa (viajan en la URL). */
export type PeriodFilters = { desde?: string; hasta?: string; etapa?: number };
