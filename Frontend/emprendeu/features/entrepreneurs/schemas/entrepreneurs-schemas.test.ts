import { describe, expect, it } from "vitest";

import { applicationFormSchema, registerEntrepreneurSchema } from "./entrepreneurs-schemas";

describe("registerEntrepreneurSchema (CU04)", () => {
  const ok = { name: "Rosa Quispe", email: "rosa@correo.com", document: "1234567 LP" };

  it("acepta un alta válida y limpia los espacios", () => {
    const r = registerEntrepreneurSchema.safeParse({ ...ok, name: "  Rosa Quispe  ", document: " 1234567 LP " });
    expect(r.success).toBe(true);
    if (r.success) expect(r.data.document).toBe("1234567 LP");
  });

  it("pide nombre y apellido, un correo válido y un documento de al menos 3 caracteres", () => {
    const msg = (input: object) => {
      const r = registerEntrepreneurSchema.safeParse({ ...ok, ...input });
      return r.success ? null : r.error.issues[0]?.message;
    };
    expect(msg({ name: "Rosa" })).toBe("Ingresa nombre y apellido.");
    expect(msg({ email: "rosa@" })).toBe("Ingresa un correo válido.");
    expect(msg({ document: "12" })).toMatch(/mínimo 3/);
    expect(msg({ document: "9".repeat(51) })).toBe("Máximo 50 caracteres.");
  });
});

describe("applicationFormSchema (formulario público)", () => {
  const ok = {
    nombre: "Lucía",
    apellido: "Vargas",
    email: "lucia@correo.com",
    telefono: "",
    documento_identidad: "",
    nombre_emprendimiento: "Dulces",
    descripcion_emprendimiento: "",
    sector: "",
    sitio_web: "",
  };

  it("solo exige nombre, apellido, correo y nombre del emprendimiento", () => {
    expect(applicationFormSchema.safeParse(ok).success).toBe(true);
  });

  it("rechaza lo obligatorio vacío y los textos demasiado largos", () => {
    for (const key of ["nombre", "apellido", "email", "nombre_emprendimiento"] as const) {
      expect(applicationFormSchema.safeParse({ ...ok, [key]: "   " }).success, key).toBe(false);
    }
    expect(applicationFormSchema.safeParse({ ...ok, email: "sin-arroba" }).success).toBe(false);
    expect(applicationFormSchema.safeParse({ ...ok, descripcion_emprendimiento: "x".repeat(2001) }).success).toBe(false);
    expect(applicationFormSchema.safeParse({ ...ok, telefono: "1".repeat(36) }).success).toBe(false);
  });

  it("deja pasar el campo trampa para que el servidor decida (un bot lo llena)", () => {
    expect(applicationFormSchema.safeParse({ ...ok, sitio_web: "http://spam" }).success).toBe(true);
  });
});
