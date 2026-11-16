import { Plus } from "lucide-react";

import { FAQ } from "../content";
import { Container, SectionHeading } from "./primitives";

/**
 * Preguntas frecuentes con `<details name="faq">` nativo: accesible por teclado y lector de pantalla
 * sin JavaScript, y solo una abierta a la vez. La transición de altura es CSS (`.faq-item`).
 */
const FAQ_JSON_LD = JSON.stringify({
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: FAQ.map((f) => ({ "@type": "Question", name: f.q, acceptedAnswer: { "@type": "Answer", text: f.a } })),
}).replace(/</g, "\\u003c");

export function Faq() {
  return (
    <section id="preguntas" aria-labelledby="faq-title" className="scroll-mt-20 bg-background pb-24 sm:pb-32">
      {/* Datos estructurados para buscadores: salen del mismo `FAQ` que se muestra. */}
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: FAQ_JSON_LD }} />
      <Container className="grid gap-10 lg:grid-cols-[0.8fr_1.2fr]">
        <SectionHeading id="faq-title" size="md">
          Lo que más nos preguntan.
        </SectionHeading>
        <div className="border-t border-border">
          {FAQ.map((f) => (
            <details key={f.q} name="faq" className="faq-item group border-b border-border">
              <summary className="flex min-h-16 cursor-pointer list-none items-center justify-between gap-6 py-5 text-left outline-none focus-visible:ring-3 focus-visible:ring-primary/30 [&::-webkit-details-marker]:hidden">
                <h3 className="font-heading text-[clamp(18px,1.8vw,22px)] font-semibold">{f.q}</h3>
                <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-blue-50 text-primary transition-colors group-hover:bg-primary group-hover:text-white">
                  <Plus aria-hidden="true" className="size-5 transition-transform duration-300 ease-[cubic-bezier(.3,1.4,.5,1)] group-open:rotate-[135deg]" />
                </span>
              </summary>
              <p className="max-w-[60ch] pb-6 text-[17px] leading-relaxed text-muted-foreground">{f.a}</p>
            </details>
          ))}
        </div>
      </Container>
    </section>
  );
}
