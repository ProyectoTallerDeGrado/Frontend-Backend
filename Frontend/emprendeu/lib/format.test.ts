import { describe, expect, it } from "vitest";

import { boDay, formatDateTime, formatTimeRange, formatWhen, toBoIso } from "./format";

describe("fechas en hora de Bolivia", () => {
  it("une día y hora con la zona de Bolivia (UTC-4)", () => {
    expect(toBoIso("2026-11-05", "09:00")).toBe("2026-11-05T09:00:00-04:00");
  });

  it("el día de Bolivia no salta al siguiente por la zona UTC", () => {
    // 23:30 en Bolivia ya es el día siguiente en UTC.
    expect(boDay(new Date("2026-11-06T03:30:00Z"))).toBe("2026-11-05");
  });

  it("el rango horario se muestra en hora de Bolivia", () => {
    expect(formatTimeRange("2026-11-05T13:00:00Z", "2026-11-05T15:00:00Z")).toBe("09:00 – 11:00");
  });

  it("un valor vacío se muestra como guion", () => {
    expect(formatDateTime(null)).toBe("—");
    expect(formatDateTime(undefined)).toBe("—");
  });

  it("formatWhen distingue hoy, ayer y fechas lejanas", () => {
    const now = new Date("2026-11-10T18:00:00Z");
    expect(formatWhen(null, now)).toBe("Nunca");
    expect(formatWhen("2026-11-10T12:00:00Z", now)).toMatch(/^Hoy, /);
    expect(formatWhen("2026-11-09T12:00:00Z", now)).toMatch(/^Ayer, /);
    expect(formatWhen("2026-11-05T12:00:00Z", now)).toBe("Hace 5 días");
  });
});
