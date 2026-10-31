import Image from "next/image";

/** Panel de marca (izquierda): logo, mensaje y órbitas decorativas. */
export function BrandPanel() {
  return (
    <section className="relative flex min-h-[520px] min-w-0 flex-[1_1_560px] flex-col justify-between overflow-hidden bg-navy-950 px-8 py-10 text-white sm:px-16 sm:py-14">
      <svg
        aria-hidden="true"
        viewBox="0 0 600 600"
        fill="none"
        className="pointer-events-none absolute -right-[180px] -bottom-[160px] size-[760px] opacity-90"
      >
        <g
          style={{ transformOrigin: "300px 300px" }}
          className="animate-[orbit-spin_60s_linear_infinite]"
        >
          <circle cx="300" cy="300" r="120" stroke="#1F4FD6" strokeOpacity=".55" strokeWidth="1.5" />
          <circle cx="420" cy="300" r="9" fill="#D61F3A" />
        </g>
        <g
          style={{ transformOrigin: "300px 300px" }}
          className="animate-[orbit-spin-reverse_90s_linear_infinite]"
        >
          <circle cx="300" cy="300" r="210" stroke="#fff" strokeOpacity=".14" strokeWidth="1.5" strokeDasharray="4 10" />
          <circle cx="300" cy="90" r="7" fill="#fff" />
        </g>
        <g
          style={{ transformOrigin: "300px 300px" }}
          className="animate-[orbit-spin_140s_linear_infinite]"
        >
          <circle cx="300" cy="300" r="290" stroke="#1F4FD6" strokeOpacity=".3" strokeWidth="1.5" />
          <circle cx="506" cy="506" r="11" fill="#1F4FD6" />
        </g>
        <circle
          cx="300"
          cy="300"
          r="56"
          fill="#0A3A8F"
          style={{ transformOrigin: "300px 300px" }}
          className="animate-[core-pulse_4s_ease-in-out_infinite]"
        />
      </svg>

      <div className="relative flex animate-[fade-up_.7s_cubic-bezier(.2,.7,.2,1)_both] items-center gap-3.5">
        <Image
          src="/brand/cie-u-logo.png"
          alt="Logo del CIE-U"
          width={56}
          height={56}
          priority
          className="size-14 rounded-[14px] object-cover ring-1 ring-white/20"
        />
        <div className="font-heading text-[15px] leading-[1.3] font-semibold tracking-[.01em]">
          Centro de Innovación y
          <br />
          Emprendimiento Universitario
        </div>
      </div>

      <div className="relative max-w-[560px]">
        <div className="inline-flex animate-[fade-up_.7s_.1s_cubic-bezier(.2,.7,.2,1)_both] items-center gap-2 rounded-full bg-white/10 px-3 py-1.5 text-[13px] font-semibold tracking-[.04em] uppercase">
          <span className="size-2 rounded-full bg-accent-bright" />
          Administrador del sistema
        </div>
        <h1 className="mt-5 mb-4 animate-[fade-up_.7s_.2s_cubic-bezier(.2,.7,.2,1)_both] font-heading text-[34px] leading-[1.1] font-bold tracking-[-.02em] text-balance sm:text-[46px]">
          Seguimiento de emprendedores, bajo control.
        </h1>
        <p className="max-w-[480px] animate-[fade-up_.7s_.3s_cubic-bezier(.2,.7,.2,1)_both] text-[17px] leading-[1.55] text-on-navy-muted text-pretty">
          Gestiona usuarios, roles, permisos y parámetros del acompañamiento a
          emprendimientos del CIE-U.
        </p>
      </div>

      <div className="relative animate-[fade-up_.7s_.4s_cubic-bezier(.2,.7,.2,1)_both] text-sm text-on-navy-faint">
        FCEE · UAGRM · Santa Cruz, Bolivia
      </div>
    </section>
  );
}
