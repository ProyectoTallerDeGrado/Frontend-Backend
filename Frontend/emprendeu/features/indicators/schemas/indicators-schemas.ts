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

export const dashboardSchema = z.object({
  desde: z.string().nullable(),
  hasta: z.string().nullable(),
  etapa_id: z.number().nullable(),
  emprendimientos_total: z.number(),
  por_etapa: z.array(z.object({ etapa_id: z.number(), etapa: z.string(), orden: z.number().nullable(), total: z.number() })),
  sesiones: z.object({ programadas: z.number(), realizadas: z.number(), canceladas: z.number() }),
  compromisos: z.object({ pendientes: z.number(), vencidos: z.number(), cumplidos_periodo: z.number() }),
  avances: z.number(),
  alertas: z.object({
    abiertas: z.number(),
    revisadas: z.number(),
    atendidas: z.number(),
    descartadas: z.number(),
    por_tipo: z.record(z.string(), z.number()),
  }),
  indicadores: z.array(
    z.object({
      tipo_indicador_id: z.number(),
      nombre: z.string(),
      unidad: z.string().nullable(),
      registros: z.number(),
      // Decimal del backend: llega como texto o número.
      promedio: z.union([z.string(), z.number()]).nullable(),
    }),
  ),
});

export const REPORT_KINDS = ["resumen", "sesiones", "alertas", "indicadores"] as const;

export const reportSchema = z.object({
  tipo: z.enum(REPORT_KINDS),
  titulo: z.string(),
  columnas: z.array(z.object({ clave: z.string(), etiqueta: z.string() })),
  filas: z.array(z.record(z.string(), z.union([z.string(), z.number(), z.null()]))),
  total: z.number(),
  truncado: z.boolean(),
  desde: z.string().nullable(),
  hasta: z.string().nullable(),
  etapa_id: z.number().nullable(),
});
