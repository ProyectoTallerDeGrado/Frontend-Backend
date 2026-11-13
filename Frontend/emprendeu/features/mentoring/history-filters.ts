import type { HistoryFilters, HistoryKind } from "./types";

const KINDS: HistoryKind[] = ["sesion", "avance", "hito", "recomendacion", "compromiso", "etapa"];
const DAY = /^\d{4}-\d{2}-\d{2}$/;

type Raw = Record<string, string | string[] | undefined>;

/** Lee los filtros del historial de la URL, descartando lo que no sea válido. */
export function parseHistoryFilters(raw: Raw): HistoryFilters {
  const tipos = [raw.tipo ?? []].flat().filter((t): t is HistoryKind => KINDS.includes(t as HistoryKind));
  const day = (value: string | string[] | undefined) => {
    const v = Array.isArray(value) ? value[0] : value;
    return v && DAY.test(v) ? v : undefined;
  };
  return {
    orden: raw.orden === "desc" ? "desc" : "asc",
    tipos: [...new Set(tipos)],
    desde: day(raw.desde),
    hasta: day(raw.hasta),
  };
}
