import { describe, expect, it } from "vitest";

import { changePasswordSchema, fieldErrors, loginSchema, registerSchema } from "./auth-schemas";

describe("loginSchema", () => {
  it("acepta un correo y una contraseña", () => {
    expect(loginSchema.safeParse({ email: " ana@correo.com ", password: "x" }).success).toBe(true);
  });

  it("rechaza lo vacío y lo mal escrito con mensajes claros", () => {
    const r = loginSchema.safeParse({ email: "no-es-correo", password: "" });
    expect(r.success).toBe(false);
    if (!r.success) {
      const errors = fieldErrors(r.error);
      expect(errors.email).toBe("Ingresa un correo válido.");
      expect(errors.password).toBe("Ingresa tu contraseña.");
    }
  });
});

describe("registerSchema", () => {
  const ok = { name: "Ana Rojas", email: "ana@correo.com", password: "clave-larga-1", confirmPassword: "clave-larga-1" };

  it("acepta datos válidos", () => {
    expect(registerSchema.safeParse(ok).success).toBe(true);
  });

  it("exige 8 caracteres y que las contraseñas coincidan", () => {
    const short = registerSchema.safeParse({ ...ok, password: "corta", confirmPassword: "corta" });
    expect(short.success).toBe(false);
    const mismatch = registerSchema.safeParse({ ...ok, confirmPassword: "otra-distinta" });
    expect(mismatch.success).toBe(false);
    if (!mismatch.success) expect(fieldErrors(mismatch.error).confirmPassword).toBe("Las contraseñas no coinciden.");
  });
});

describe("changePasswordSchema", () => {
  const base = { currentPassword: "actual-1234", newPassword: "nueva-clave-99", confirmPassword: "nueva-clave-99" };

  it("acepta un cambio válido", () => {
    expect(changePasswordSchema.safeParse(base).success).toBe(true);
  });

  it("rechaza repetir la actual, contraseñas distintas y un largo excesivo", () => {
    expect(changePasswordSchema.safeParse({ ...base, newPassword: "actual-1234", confirmPassword: "actual-1234" }).success).toBe(false);
    expect(changePasswordSchema.safeParse({ ...base, confirmPassword: "x" }).success).toBe(false);
    const long = "a".repeat(129);
    expect(changePasswordSchema.safeParse({ ...base, newPassword: long, confirmPassword: long }).success).toBe(false);
  });
});
