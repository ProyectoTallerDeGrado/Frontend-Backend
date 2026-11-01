import { z } from "zod";

export const overviewSchema = z.object({
  usuarios: z.object({
    total: z.number(),
    habilitadas: z.number(),
    deshabilitadas: z.number(),
    por_rol: z.record(z.string(), z.number()),
  }),
  acciones_auditadas: z.number(),
  emprendimientos_activos: z.number(),
  alertas_abiertas: z.number(),
  servicios: z.array(z.object({ nombre: z.string(), detalle: z.string(), estado: z.string() })),
});
