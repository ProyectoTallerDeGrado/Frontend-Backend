import { AppShowcase } from "./app-showcase";
import { ApplySteps } from "./apply-steps";
import { ClosingCta } from "./closing-cta";
import { Faq } from "./faq";
import { Hero } from "./hero";
import { JourneySection } from "./journey-section";
import { Marquee } from "./marquee";
import { ProblemSolution } from "./problem-solution";
import { SiteFooter } from "./site-footer";
import { SiteHeader } from "./site-header";
import { StaffStrip } from "./staff-strip";

/**
 * Landing pública del CIE-U, contada como historia: gancho → el problema → el giro (la solución)
 * → el camino → qué contiene la app → quién está detrás → cómo postular → cierre.
 */
export function LandingView({ signedIn }: { signedIn: boolean }) {
  return (
    <div className="landing flex min-h-screen flex-col bg-background">
      {/* Sin JavaScript no hay animaciones: el contenido debe verse igual. */}
      <noscript>
        <style>{`[data-anim="pending"] [data-reveal]{opacity:1 !important}`}</style>
      </noscript>
      <SiteHeader signedIn={signedIn} />
      <main id="contenido">
        <Hero signedIn={signedIn} />
        <Marquee />
        <ProblemSolution />
        <JourneySection />
        <AppShowcase />
        <StaffStrip />
        <ApplySteps />
        <Faq />
        <ClosingCta />
      </main>
      <SiteFooter signedIn={signedIn} />
    </div>
  );
}
