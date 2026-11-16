import Image from "next/image";
import Link from "next/link";

import { CTA, NAV_LINKS } from "../content";
import { MobileMenu } from "./mobile-menu";
import { Container, LandingButton } from "./primitives";

/**
 * Cabecera fija: transparente sobre el hero, sólida al bajar y con barra de progreso de lectura.
 * Todo eso es CSS ligado al scroll (`.site-header`, `.site-progress` en `globals.css`): sin JavaScript.
 * Bajo `lg` los enlaces de sección van en `MobileMenu` (la única pieza cliente de la cabecera).
 */
export function SiteHeader({ signedIn }: { signedIn: boolean }) {
  return (
    <header className="site-header fixed inset-x-0 top-0 z-50 text-white">
      <Container className="flex h-[72px] items-center gap-6">
        <Link href="/" className="flex items-center gap-3 rounded-lg outline-none focus-visible:ring-3 focus-visible:ring-white/50">
          <Image src="/brand/cie-u-logo.png" alt="" width={40} height={40} className="size-10 rounded-lg object-cover ring-1 ring-white/20" />
          <span className="font-heading text-lg font-bold">CIE-U</span>
        </Link>
        <nav aria-label="Secciones" className="ml-4 hidden items-center gap-1 lg:flex">
          {NAV_LINKS.map((l) => (
            <a
              key={l.href}
              href={l.href}
              className="rounded-lg px-3 py-2 text-[15px] font-semibold text-on-navy-muted outline-none transition-colors hover:text-white focus-visible:ring-3 focus-visible:ring-white/40"
            >
              {l.label}
            </a>
          ))}
        </nav>
        <div className="ml-auto flex items-center gap-2">
          {/* El panel es solo para el personal: el estudiante usa la app. En móvil este enlace queda en el pie. */}
          <Link
            href={signedIn ? "/panel" : "/login"}
            className="hidden min-h-11 items-center rounded-lg px-3 text-sm font-semibold text-on-navy-muted outline-none transition-colors hover:text-white focus-visible:ring-3 focus-visible:ring-white/40 sm:inline-flex"
          >
            {signedIn ? CTA.panel : CTA.staff}
          </Link>
          <LandingButton href="/apply" size="sm">
            {CTA.applyShort}
          </LandingButton>
          <MobileMenu staffHref={signedIn ? "/panel" : "/login"} staffLabel={signedIn ? CTA.panel : CTA.staff} />
        </div>
      </Container>
      <span aria-hidden="true" className="site-progress absolute bottom-0 left-0 h-[3px] w-full bg-accent-bright" />
    </header>
  );
}
