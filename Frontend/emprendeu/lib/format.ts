const TZ = "America/La_Paz";

const dayKey = new Intl.DateTimeFormat("en-CA", { timeZone: TZ });
const hourMinute = new Intl.DateTimeFormat("es-BO", {
  timeZone: TZ,
  hour: "2-digit",
  minute: "2-digit",
  hour12: false,
});
const fullDate = new Intl.DateTimeFormat("es-BO", {
  timeZone: TZ,
  day: "2-digit",
  month: "short",
  year: "numeric",
});

const DAY_MS = 86_400_000;

function dayNumber(date: Date): number {
  const [y, m, d] = dayKey.format(date).split("-").map(Number);
  return Date.UTC(y, m - 1, d) / DAY_MS;
}

/** «Hoy, 08:12», «Ayer, 17:20», «Hace 3 días», «Nunca». Siempre en hora de Bolivia. */
export function formatWhen(iso: string | null | undefined, now: Date = new Date()): string {
  if (!iso) return "Nunca";
  const date = new Date(iso);
  const diff = dayNumber(now) - dayNumber(date);
  const time = hourMinute.format(date);
  if (diff <= 0) return `Hoy, ${time}`;
  if (diff === 1) return `Ayer, ${time}`;
  if (diff < 30) return `Hace ${diff} días`;
  return fullDate.format(date);
}

export function initials(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase();
}
