import { describe, expect, it } from "vitest";

import { DOCUMENT_MAX_MB, validateDocumentFile } from "./documents-schemas";

const file = (name: string, size = 10) => new File([new Uint8Array(size)], name);

describe("validateDocumentFile (CU30)", () => {
  it("sin archivo o vacío pide elegir uno", () => {
    expect(validateDocumentFile(null)).toBe("Elige un archivo.");
    expect(validateDocumentFile(file("vacio.pdf", 0))).toBe("Elige un archivo.");
  });

  it("acepta las extensiones permitidas sin distinguir mayúsculas", () => {
    expect(validateDocumentFile(file("plan.pdf"))).toBeNull();
    expect(validateDocumentFile(file("FOTO.JPG"))).toBeNull();
  });

  it("rechaza extensiones que el backend no admite", () => {
    expect(validateDocumentFile(file("virus.exe"))).toMatch(/Formato no permitido/);
    expect(validateDocumentFile(file("sin-extension"))).toMatch(/Formato no permitido/);
  });

  it("rechaza archivos por encima del tope", () => {
    const big = file("grande.pdf", DOCUMENT_MAX_MB * 1024 * 1024 + 1);
    expect(validateDocumentFile(big)).toMatch(/supera/);
  });
});
