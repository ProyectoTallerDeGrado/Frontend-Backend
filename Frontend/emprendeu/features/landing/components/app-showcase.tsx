"use client";

import { animate, onScroll, utils } from "animejs";

import { APP_FEATURES, type AppFeatureKey } from "../content";
import { useAnimeScope } from "../hooks/use-anime-scope";
import { moveTab, PhoneScreens, playScreen } from "./phone-screens";

/**
 * «Qué contiene la app»: un teléfono fijo cambia de pantalla según la característica que se lee.
 * Escritorio: la cambia el scroll. Móvil: el teléfono recorre las pantallas solo mientras está a la vista.
 */
export function AppShowcase() {
  const ref = useAnimeScope<HTMLElement>((_reduced, root) => {
    const phone = root.querySelector<HTMLElement>(".phone-display")!;
    const screens = new Map<AppFeatureKey, HTMLElement>();
    phone.querySelectorAll<HTMLElement>(".phone-screen").forEach((s) => screens.set(s.dataset.screen as AppFeatureKey, s));
    const order = APP_FEATURES.map((f) => f.key);
    let current: AppFeatureKey | null = null;

    utils.set([...screens.values()], { opacity: 0, x: "30%" });

    const show = (key: AppFeatureKey) => {
      if (key === current) return;
      const forward = current === null || order.indexOf(key) > order.indexOf(current);
      if (current) animate(screens.get(current)!, { opacity: 0, x: forward ? "-30%" : "30%", duration: 450, ease: "in(2)" });
      const next = screens.get(key)!;
      animate(next, { opacity: [0, 1], x: [forward ? "30%" : "-30%", "0%"], duration: 600, ease: "out(4)" });
      playScreen(key, next);
      moveTab(key, phone);
      root.querySelectorAll<HTMLElement>(".feature").forEach((f) => f.toggleAttribute("data-active", f.dataset.key === key));
      current = key;
    };

    const isDesktop = window.matchMedia("(min-width: 1024px)").matches;
    if (isDesktop) {
      root.querySelectorAll<HTMLElement>(".feature").forEach((feature) => {
        onScroll({
          target: feature,
          enter: "center top",
          leave: "center bottom",
          onEnter: () => show(feature.dataset.key as AppFeatureKey),
        });
      });
      show(order[0]);
      return;
    }

    // Móvil: recorrido automático mientras el teléfono está a la vista.
    let i = 0;
    let visible = false;
    const io = new IntersectionObserver(([e]) => {
      visible = e.isIntersecting;
      if (visible && current === null) show(order[0]);
    });
    io.observe(phone);
    const timer = window.setInterval(() => {
      if (!visible || document.hidden) return;
      i = (i + 1) % order.length;
      show(order[i]);
    }, 3600);
    return () => {
      io.disconnect();
      window.clearInterval(timer);
    };
  });

  return (
    <section ref={ref} data-anim="pending" id="app" aria-labelledby="app-title" className="scroll-mt-16 bg-card py-24 sm:py-32">
      <div className="mx-auto max-w-[1240px] px-5 sm:px-8">
        <h2 id="app-title" className="max-w-[16ch] font-heading text-[clamp(36px,5vw,64px)] leading-[1.02] font-bold tracking-[-.03em] text-balance">
          Todo cabe en tu bolsillo.
        </h2>
        <p className="mt-5 max-w-[56ch] text-lg leading-relaxed text-muted-foreground">
          Al entrar al programa recibes la app del emprendedor. Esto es lo que trae.
        </p>

        <div className="mt-14 grid gap-12 lg:grid-cols-[minmax(0,420px)_1fr] lg:gap-20">
          <div className="lg:sticky lg:top-24 lg:h-fit">
            <div aria-hidden="true" className="relative mx-auto w-[290px]">
              <span className="absolute -inset-10 -z-10 rounded-full bg-primary/15 blur-3xl" />
              <div className="rounded-[46px] bg-navy-950 p-3 shadow-[0_40px_80px_-30px_rgb(2_31_80/.6)]">
                <div className="phone-display relative h-[580px] overflow-hidden rounded-[36px] bg-card text-foreground">
                  <div className="flex h-9 items-center justify-between px-6 pt-1 text-[11px] font-bold">
                    <span>9:41</span>
                    <span className="h-5 w-20 rounded-full bg-navy-950" />
                    <span>100%</span>
                  </div>
                  <div className="absolute inset-x-0 top-9 bottom-0">
                    <PhoneScreens />
                  </div>
                </div>
              </div>
            </div>
          </div>

          <ul className="flex flex-col">
            {APP_FEATURES.map((f) => (
              <li
                key={f.key}
                data-key={f.key}
                className="feature group border-l-4 border-border py-8 pl-6 transition-colors duration-500 data-active:border-primary lg:flex lg:min-h-[62vh] lg:flex-col lg:justify-center lg:py-0"
              >
                <h3 className="font-heading text-[clamp(24px,2.6vw,34px)] leading-tight font-bold tracking-[-.02em] text-muted-foreground transition-colors duration-500 group-data-active:text-foreground">
                  {f.title}
                </h3>
                <p className="mt-3 max-w-[46ch] text-[17px] leading-relaxed text-muted-foreground">{f.text}</p>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
