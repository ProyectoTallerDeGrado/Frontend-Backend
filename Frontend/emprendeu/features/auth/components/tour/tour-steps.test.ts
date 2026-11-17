import { describe, expect, it } from "vitest";

import { buildTourSteps, tourGroupId } from "./tour-steps";

describe("buildTourSteps", () => {
  const groups = [
    { label: "Inicio", items: [{ href: "/panel", label: "Resumen" }] },
    { label: "Acompañamiento", items: [{ href: "/mentoring/sessions", label: "Sesiones" }] },
    { label: "Vacío", items: [] },
  ];

  it("arma bienvenida, menú, un paso por grupo visible, cuenta, ayuda y cierre", () => {
    const steps = buildTourSteps({ firstName: "Ana", groups });
    expect(steps.map((s) => s.id)).toEqual([
      "welcome",
      "nav",
      "nav-group-inicio",
      "nav-group-acompanamiento",
      "account",
      "help",
      "done",
    ]);
    expect(steps[0].title).toContain("Ana");
  });

  it("describe solo las pantallas que la persona ve", () => {
    const group = buildTourSteps({ firstName: "Ana", groups }).find((s) => s.id === "nav-group-acompanamiento");
    expect(group?.items).toEqual([{ label: "Sesiones", text: expect.stringContaining("mentorías") }]);
  });

  it("genera ids sin tildes ni espacios", () => {
    expect(tourGroupId("Configuración")).toBe("nav-group-configuracion");
  });
});
