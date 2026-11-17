import { describe, expect, it } from "vitest";

import { helpSuggestionsFor } from "./help-suggestions";

describe("helpSuggestionsFor", () => {
  it("prioriza las preguntas de la pantalla actual (la ruta más específica)", () => {
    const list = helpSuggestionsFor("/mentoring/sessions");
    expect(list[0]).toBe("¿Cómo registro una sesión realizada?");
    expect(list).toHaveLength(3);
  });

  it("reconoce subrutas", () => {
    expect(helpSuggestionsFor("/ventures/12/progress")[0]).toBe("¿Cómo avanzo un emprendimiento de etapa?");
  });

  it("sin coincidencia devuelve las generales", () => {
    expect(helpSuggestionsFor("/panel")).toEqual(["¿Qué puedo hacer en el sistema?", "¿Dónde encuentro cada pantalla?"]);
  });
});
