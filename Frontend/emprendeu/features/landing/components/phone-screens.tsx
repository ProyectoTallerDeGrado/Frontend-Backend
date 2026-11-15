import { animate, createTimeline, splitText, stagger, utils } from "animejs";
import { Bot, CalendarDays, Check, Home, Lock, Map, User, WifiOff, type LucideIcon } from "lucide-react";

import { cn } from "@/lib/utils";

import { COACH_CHAT, PHONE_TABS, type AppFeatureKey } from "../content";
import { part } from "../hooks/use-anime-scope";

/** Pestaña de la barra inferior de la app que corresponde a cada pantalla. */
const TAB_OF: Record<AppFeatureKey, number> = { home: 0, journey: 1, coach: 2, mentoring: 3 };
const TAB_ICONS: LucideIcon[] = [Home, Map, Bot, CalendarDays, User];

const JOURNEY_NODES = [
  { t: "Completar el perfil", s: "done" },
  { t: "Definir la propuesta de valor", s: "done" },
  { t: "Entrevistar a 5 clientes", s: "now" },
  { t: "Construir un prototipo", s: "lock" },
] as const;

const SLOTS = ["Lun 9:00", "Lun 15:00", "Mar 10:00", "Mié 11:00", "Jue 16:00", "Vie 9:00"];

function Screen({ k, children }: { k: AppFeatureKey; children: React.ReactNode }) {
  return (
    <div
      data-part="phone-screen"
      data-screen={k}
      className={cn("absolute inset-0 flex flex-col gap-3 overflow-hidden px-4 pt-3 pb-20", k !== "home" && "opacity-0")}
    >
      {children}
    </div>
  );
}

/** Pantallas de ejemplo de la app del emprendedor (datos ilustrativos, no reales). */
export function PhoneScreens() {
  return (
    <>
      <Screen k="home">
        <p className="text-[13px] text-muted-foreground">Hola, Camila</p>
        <p className="font-heading text-xl leading-tight font-bold">Tu semana</p>
        <div className="rounded-xl bg-navy-900 p-4 text-white">
          <div className="flex items-baseline justify-between text-[12px] text-on-navy-muted">
            <span>Nivel 2</span>
            <span>
              <span data-part="ph-xp" className="tabular-nums">
                340
              </span>{" "}
              / 400 XP
            </span>
          </div>
          <div className="mt-2 h-2 overflow-hidden rounded-full bg-white/15">
            <div data-part="ph-xpbar" className="h-full w-[85%] origin-left rounded-full bg-on-navy-dim" />
          </div>
        </div>
        <div data-part="ph-card" className="rounded-xl border border-border bg-card p-3.5">
          <p className="text-[11px] font-semibold text-muted-foreground">Siguiente reto</p>
          <p className="mt-0.5 text-[14px] font-bold">Entrevistar a 5 clientes</p>
          <span className="mt-2 inline-block rounded-full bg-danger-tint px-2 py-0.5 text-[11px] font-bold text-danger-foreground">+120 XP</span>
        </div>
        <div data-part="ph-card" className="rounded-xl border border-border bg-card p-3.5">
          <p className="text-[11px] font-semibold text-muted-foreground">Compromiso con tu asesor</p>
          <p className="mt-0.5 text-[14px] font-bold">Traer 3 precios de proveedores</p>
          <span className="mt-2 inline-block rounded-full bg-warning-tint px-2 py-0.5 text-[11px] font-bold text-warning-foreground">Vence el jueves</span>
        </div>
      </Screen>

      <Screen k="journey">
        <p className="font-heading text-xl font-bold">Camino</p>
        <span className="w-fit rounded-full bg-blue-50 px-2.5 py-1 text-[11px] font-bold text-info-foreground">Preincubación</span>
        <div className="relative mt-2 flex flex-1 flex-col justify-between py-2 pl-10">
          <span className="absolute top-4 bottom-4 left-[17px] w-1 rounded-full bg-border" />
          <span data-part="ph-pathfill" className="absolute top-4 left-[17px] h-[58%] w-1 origin-top rounded-full bg-success" />
          {JOURNEY_NODES.map((n) => (
            <div key={n.t} data-part="ph-node" className="relative flex items-center gap-3">
              <span
                className={cn(
                  "absolute -left-10 flex size-9 items-center justify-center rounded-full",
                  n.s === "done" && "bg-success text-white",
                  n.s === "now" && "bg-primary text-white ring-4 ring-blue-50",
                  n.s === "lock" && "bg-muted text-muted-foreground",
                )}
              >
                {n.s === "done" ? <Check className="size-4" strokeWidth={3} /> : n.s === "lock" ? <Lock className="size-3.5" /> : "3"}
              </span>
              <span className={cn("text-[13px]", n.s === "lock" ? "text-muted-foreground" : "font-semibold")}>{n.t}</span>
            </div>
          ))}
        </div>
        <span data-part="ph-xpchip" className="absolute right-4 bottom-24 rounded-full bg-accent-bright px-3 py-1.5 text-[12px] font-bold text-on-accent">
          +120 XP
        </span>
      </Screen>

      <Screen k="mentoring">
        <p className="font-heading text-xl font-bold">Agendar mentoría</p>
        <p className="text-[12px] text-muted-foreground">Horarios libres de tu asesor</p>
        <div className="grid grid-cols-3 gap-2">
          {SLOTS.map((slot, i) => (
            <span
              key={slot}
              data-part={i === 4 ? "ph-slot ph-slot-pick" : "ph-slot"}
              className="rounded-lg border border-border bg-card px-1 py-2.5 text-center text-[11px] font-semibold"
            >
              {slot}
            </span>
          ))}
        </div>
        <div className="mt-1 rounded-xl bg-background p-3 text-[12px] leading-snug">
          <p className="font-bold">Última sesión</p>
          <p className="mt-1 text-muted-foreground">Recomendación: probar precio con 10 clientes antes de producir.</p>
        </div>
        <div data-part="ph-toast" className="absolute inset-x-4 bottom-24 flex items-center gap-2 rounded-xl bg-navy-900 px-3.5 py-3 text-[12px] font-semibold text-white">
          <span className="flex size-6 items-center justify-center rounded-full bg-success">
            <Check className="size-3.5" strokeWidth={3} />
          </span>
          Sesión agendada: jueves 16:00
        </div>
      </Screen>

      <Screen k="coach">
        <div className="flex items-center justify-between">
          <p className="font-heading text-xl font-bold">Coach IA</p>
          <span data-part="ph-offline" className="flex items-center gap-1 rounded-full bg-success-tint px-2 py-1 text-[10px] font-bold text-success-foreground">
            <WifiOff className="size-3" /> Sin internet
          </span>
        </div>
        <p data-part="ph-q" className="ml-auto max-w-[85%] rounded-xl rounded-br-sm bg-primary px-3 py-2.5 text-[12.5px] text-white">
          {COACH_CHAT.question}
        </p>
        <div className="max-w-[90%] rounded-xl rounded-bl-sm bg-background px-3 py-2.5 text-[12.5px] leading-snug">
          <p data-part="ph-a">{COACH_CHAT.answer}</p>
          <p data-part="ph-src" className="mt-1.5 text-[11px] font-bold text-primary">
            Fuente: {COACH_CHAT.source}
          </p>
        </div>
      </Screen>

      {/* Barra inferior de la app */}
      <nav className="absolute inset-x-0 bottom-0 flex h-16 items-center justify-around border-t border-border bg-card px-1">
        <span data-part="ph-tab-indicator" className="absolute top-2 left-0 h-12 w-[20%] rounded-xl bg-blue-50" />
        {PHONE_TABS.map((label, i) => {
          const Icon = TAB_ICONS[i];
          return (
            <span key={label} className="relative flex w-[20%] flex-col items-center gap-0.5 text-[9.5px] font-semibold text-muted-foreground">
              <Icon className="size-[18px]" />
              {label}
            </span>
          );
        })}
      </nav>
    </>
  );
}

/** Mueve el indicador de la barra inferior a la pestaña de la pantalla `key`. */
export function moveTab(key: AppFeatureKey, phone: HTMLElement) {
  const indicator = phone.querySelector<HTMLElement>(part("ph-tab-indicator"));
  if (indicator) animate(indicator, { x: `${TAB_OF[key] * 100}%`, duration: 450, ease: "out(4)" });
}

const token = (el: HTMLElement, name: string) => getComputedStyle(el).getPropertyValue(name).trim();

/** Micro-animación propia de cada pantalla al mostrarse. */
export function playScreen(key: AppFeatureKey, screen: HTMLElement) {
  const $ = (name: string) => screen.querySelectorAll<HTMLElement>(part(name));
  switch (key) {
    case "home": {
      const xp = $("ph-xp")[0];
      const c = { v: 0 };
      if (xp) animate(c, { v: 340, duration: 1200, ease: "out(3)", onUpdate: () => (xp.textContent = String(Math.round(c.v))) });
      animate($("ph-xpbar"), { scaleX: [0, 1], duration: 1200, ease: "out(4)" });
      animate($("ph-card"), { opacity: [0, 1], y: [16, 0], delay: stagger(120, { start: 200 }), duration: 600, ease: "out(3)" });
      break;
    }
    case "journey":
      animate($("ph-pathfill"), { scaleY: [0, 1], duration: 1100, ease: "inOut(3)" });
      animate($("ph-node"), { opacity: [0, 1], x: [-14, 0], delay: stagger(140), duration: 500, ease: "out(3)" });
      animate($("ph-xpchip"), { scale: [0, 1.15, 1], rotate: [-20, 0], opacity: [0, 1], delay: 700, duration: 800, ease: "outElastic(1, .5)" });
      break;
    case "mentoring":
      createTimeline()
        .add($("ph-slot"), { opacity: [0, 1], scale: [0.8, 1], delay: stagger(60), duration: 400, ease: "outBack(2)" })
        .add($("ph-slot-pick"), {
          backgroundColor: [token(screen, "--card"), token(screen, "--primary")],
          color: [token(screen, "--foreground"), token(screen, "--primary-foreground")],
          scale: [1, 1.08, 1],
          duration: 500,
        })
        .add($("ph-toast"), { y: [80, 0], opacity: [0, 1], duration: 600, ease: "outBack(1.6)" }, "+=150");
      break;
    case "coach": {
      const answer = $("ph-a")[0];
      if (!answer) break;
      const { words } = splitText(answer, { words: true });
      utils.set(words, { opacity: 0 });
      createTimeline()
        .add($("ph-offline"), { scale: [0, 1], duration: 500, ease: "outBack(3)" })
        .add($("ph-q"), { opacity: [0, 1], y: [12, 0], duration: 450, ease: "out(3)" }, 100)
        .add(words, { opacity: 1, duration: 200, delay: stagger(50) }, "+=400")
        .add($("ph-src"), { opacity: [0, 1], duration: 400 });
      break;
    }
  }
}
