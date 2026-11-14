import { formatDateTime } from "@/lib/format";

import type { KnowledgeGaps } from "../types";

/**
 * Preguntas que el coach respondió con «no encontré información», agrupadas por tema.
 * Dicen qué documentos faltan en la base. Son anónimas: no muestran quién preguntó.
 */
export function KnowledgeGapsSection({ gaps }: { gaps: KnowledgeGaps }) {
  return (
    <section aria-labelledby="gaps-title" className="mt-8">
      <h2 id="gaps-title" className="font-heading text-lg font-semibold">
        Preguntas sin respuesta
      </h2>
      <p className="mt-1 text-[13px] text-muted-foreground">
        Lo que los emprendedores preguntaron en los últimos 90 días y el coach no pudo responder con la base.
        Sube documentos sobre estos temas. Son anónimas; las preguntas hechas a la IA del celular no se cuentan.
        {!gaps.por_similitud && " El servicio de IA no responde: solo se unen las preguntas escritas igual."}
      </p>

      {gaps.temas.length === 0 ? (
        <div className="mt-4 rounded-2xl border border-border bg-card px-5 py-8 text-center text-muted-foreground">
          No hay preguntas sin respuesta en este periodo.
        </div>
      ) : (
        <ul className="mt-4 grid gap-3">
          {gaps.temas.map((t) => (
            <li key={t.tema} className="rounded-2xl border border-border bg-card px-5 py-4">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div className="min-w-0 flex-1 font-semibold">«{t.tema}»</div>
                <span className="shrink-0 rounded-full bg-blue-50 px-3 py-1 text-[13px] font-bold text-primary">
                  {t.veces} {t.veces === 1 ? "vez" : "veces"}
                </span>
              </div>
              {t.ejemplos.length > 0 && (
                <div className="mt-2 text-[13px] text-muted-foreground">
                  También: {t.ejemplos.map((e) => `«${e}»`).join(" · ")}
                </div>
              )}
              <div className="mt-1 text-[12px] text-muted-foreground">Última vez: {formatDateTime(t.ultima_fecha)}</div>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
