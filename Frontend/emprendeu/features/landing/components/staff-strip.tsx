import { BellRing, CalendarDays, ChartColumn, type LucideIcon } from "lucide-react";

import { STAFF_POINTS, type StaffIcon } from "../content";
import { Container, SectionHeading } from "./primitives";

const ICONS: Record<StaffIcon, LucideIcon> = { alert: BellRing, calendar: CalendarDays, chart: ChartColumn };

/** «Y detrás, el CIE-U»: el seguimiento del personal, contado desde el lado del estudiante. */
export function StaffStrip() {
  return (
    <section aria-labelledby="detras-title" className="bg-blue-50 py-20">
      <Container className="grid gap-10 lg:grid-cols-[0.9fr_1.1fr] lg:items-center">
        <div>
          <SectionHeading id="detras-title" size="md" className="max-w-none text-navy-950">
            Y detrás de la app, personas.
          </SectionHeading>
          <p className="mt-4 max-w-[46ch] text-lg leading-relaxed text-info-foreground">
            Asesores y coordinación siguen tu avance desde el panel del CIE-U. No es para vigilarte: es para que nadie
            se quede atrás.
          </p>
        </div>
        <ul className="grid gap-3 sm:grid-cols-3 lg:grid-cols-1">
          {STAFF_POINTS.map((p) => {
            const Icon = ICONS[p.icon];
            return (
              <li key={p.text} className="flex items-center gap-4 rounded-xl bg-card px-5 py-4 text-[16px] font-semibold text-navy-950">
                <span className="flex size-11 shrink-0 items-center justify-center rounded-lg bg-primary text-white">
                  <Icon aria-hidden="true" className="size-5" />
                </span>
                {p.text}
              </li>
            );
          })}
        </ul>
      </Container>
    </section>
  );
}
