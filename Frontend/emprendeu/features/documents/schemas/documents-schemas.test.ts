import { describe, expect, it } from "vitest";

import { DOCUMENT_EXTENSIONS, DOCUMENT_MAX_MB, validateDocumentFile } from "./documents-schemas";

describe("validateDocumentFile (CU30)", () => {
  it("acepta todas las extensiones que permite el servidor", () => {
    for (const ext of DOCUMENT_EXTENSIONS) {
      expect(validateDocumentFile({ name: `archivo${ext.toUpperCase()}`, size: 10 }), ext).toBeNull();
    }
  });

  it("rechaza lo que el servidor rechazaría", () => {
    expect(validateDocumentFile({ name: "script.sh", size: 10 })).toBe("Ese tipo de archivo no es válido.");
    expect(validateDocumentFile({ name: "sin-extension", size: 10 })).toBe("Ese tipo de archivo no es válido.");
    expect(validateDocumentFile({ name: "a.pdf", size: 0 })).toBe("Elige un archivo con contenido.");
    expect(validateDocumentFile({ name: "a.pdf", size: DOCUMENT_MAX_MB * 1024 * 1024 + 1 })).toMatch(/supera/);
  });
});
