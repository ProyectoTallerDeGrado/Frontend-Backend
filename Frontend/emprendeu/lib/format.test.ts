import { describe, expect, it } from "vitest";

import { boDay, boTime, formatDateTime, formatTimeRange, formatWhen, initials, toBoIso } from "./format";

describe("hora de Bolivia (UTC-4 todo el año)", () => {
  it("convierte el día y la hora escritos a un instante con zona", () => {
    expect(toBoIso("2030-05-01", "09:30")).toBe("2030-05-01T09:30:00-04:00");
    // 09:30 en Bolivia son las 13:30 UTC
    expect(new Date(toBoIso("2030-05-01", "09:30")).toISOString()).toBe("2030-05-01T13:30:00.000Z");
  });

  it("muestra el día y la hora locales de un instante UTC, también cuando cambia el día", () => {
    expect(boDay("2030-05-01T13:30:00Z")).toBe("2030-05-01");
    expect(boTime(new Date("2030-05-01T13:30:00Z"))).toBe("09:30");
    // 02:00 UTC es todavía el día anterior en Bolivia
    expect(boDay("2030-05-02T02:00:00Z")).toBe("2030-05-01");
    expect(boTime(new Date("2030-05-02T02:00:00Z"))).toBe("22:00");
  });

  it("ida y vuelta: lo que se escribe es lo que se vuelve a mostrar", () => {
    const iso = toBoIso("2031-01-15", "18:45");
    expect(boDay(iso)).toBe("2031-01-15");
    expect(boTime(new Date(iso))).toBe("18:45");
  });

  it("da un rango de horas y un texto de fecha legibles", () => {
    expect(formatTimeRange("2030-05-01T13:00:00Z", "2030-05-01T15:00:00Z")).toBe("09:00 – 11:00");
    expect(formatDateTime("2030-05-01T13:30:00Z")).toContain("09:30");
    expect(formatDateTime(null)).toBe("—");
    expect(formatDateTime(undefined)).toBe("—");
  });
});

describe("formatWhen", () => {
  const now = new Date("2030-05-10T16:00:00Z"); // 12:00 en Bolivia

  it("dice Nunca sin fecha", () => {
    expect(formatWhen(null, now)).toBe("Nunca");
  });

  it("usa Hoy, Ayer y Hace N días según el día en Bolivia", () => {
    expect(formatWhen("2030-05-10T13:05:00Z", now)).toBe("Hoy, 09:05");
    expect(formatWhen("2030-05-09T21:20:00Z", now)).toBe("Ayer, 17:20");
    expect(formatWhen("2030-05-07T15:00:00Z", now)).toBe("Hace 3 días");
  });

  it("pasado el mes, muestra la fecha completa", () => {
    expect(formatWhen("2030-03-01T15:00:00Z", now)).toMatch(/2030/);
  });

  it("cuenta el día por la hora de Bolivia, no la de UTC", () => {
    // Pasada la medianoche UTC sigue siendo «hoy» en Bolivia (20:30 del día 10)
    expect(formatWhen("2030-05-10T22:00:00Z", new Date("2030-05-11T00:30:00Z"))).toMatch(/^Hoy/);
  });
});

describe("initials", () => {
  it("toma las iniciales de las dos primeras palabras", () => {
    expect(initials("Camila Justiniano Rojas")).toBe("CJ");
    expect(initials("  ana  ")).toBe("A");
    expect(initials("")).toBe("");
  });
});
