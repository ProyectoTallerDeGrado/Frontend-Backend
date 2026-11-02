import { describe, expect, it } from "vitest";

import { KNOWLEDGE_MAX_MB, validateKnowledgeFile } from "./ai-schemas";

const MB = 1024 * 1024;

describe("validateKnowledgeFile (CU31)", () => {
  it("acepta txt, md, pdf y docx, sin importar mayúsculas", () => {
    for (const name of ["notas.txt", "guia.MD", "plan.pdf", "Informe.DOCX"]) {
      expect(validateKnowledgeFile({ name, size: 1000 }), name).toBeNull();
    }
  });

  it("rechaza otros formatos, archivos vacíos y los que pasan del tope", () => {
    expect(validateKnowledgeFile({ name: "virus.exe", size: 1000 })).toMatch(/Usa un archivo/);
    expect(validateKnowledgeFile({ name: "hoja.xlsx", size: 1000 })).toMatch(/Usa un archivo/);
    expect(validateKnowledgeFile({ name: "vacio.txt", size: 0 })).toBe("Elige un archivo con contenido.");
    expect(validateKnowledgeFile(null)).toBe("Elige un archivo con contenido.");
    expect(validateKnowledgeFile({ name: "grande.pdf", size: KNOWLEDGE_MAX_MB * MB + 1 })).toBe(
      `El archivo supera ${KNOWLEDGE_MAX_MB} MB.`,
    );
    expect(validateKnowledgeFile({ name: "justo.pdf", size: KNOWLEDGE_MAX_MB * MB })).toBeNull();
  });
});
