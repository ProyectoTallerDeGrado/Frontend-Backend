import { describe, expect, it } from "vitest";

import {
  changePasswordSchema,
  fieldErrors,
  forgotPasswordSchema,
  loginSchema,
  registerSchema,
  resetPasswordSchema,
} from "./auth-schemas";

describe("loginSchema", () => {
  it("pide correo y contraseña", () => {
    const parsed = loginSchema.safeParse({ email: "", password: "" });
    expect(parsed.success).toBe(false);
    if (!parsed.success) {
      expect(fieldErrors(parsed.error)).toEqual({
        email: "Ingresa tu correo electrónico.",
        password: "Ingresa tu contraseña.",
      });
    }
  });

  it("recorta el correo y lo valida", () => {
    expect(loginSchema.parse({ email: "  a@b.co ", password: "x" }).email).toBe("a@b.co");
    expect(loginSchema.safeParse({ email: "no-es-correo", password: "x" }).success).toBe(false);
  });
});

describe("registerSchema", () => {
  const base = { name: "Ana Pérez", email: "ana@uagrm.edu.bo", password: "clave-larga-1", confirmPassword: "clave-larga-1" };

  it("acepta datos correctos", () => {
    expect(registerSchema.safeParse(base).success).toBe(true);
  });

  it("exige 8 caracteres y que coincidan", () => {
    const short = registerSchema.safeParse({ ...base, password: "corta", confirmPassword: "corta" });
    expect(short.success).toBe(false);
    const different = registerSchema.safeParse({ ...base, confirmPassword: "otra-clave-9" });
    expect(different.success).toBe(false);
    if (!different.success) expect(fieldErrors(different.error).confirmPassword).toBe("Las contraseñas no coinciden.");
  });
});

describe("changePasswordSchema", () => {
  it("la clave nueva debe ser distinta de la actual", () => {
    const parsed = changePasswordSchema.safeParse({
      currentPassword: "misma-clave-1",
      newPassword: "misma-clave-1",
      confirmPassword: "misma-clave-1",
    });
    expect(parsed.success).toBe(false);
    if (!parsed.success) expect(fieldErrors(parsed.error).newPassword).toMatch(/distinta/);
  });
});

describe("recuperación de contraseña (CU01)", () => {
  it("forgotPasswordSchema valida el correo", () => {
    expect(forgotPasswordSchema.safeParse({ email: "ana@correo.com" }).success).toBe(true);
    expect(forgotPasswordSchema.safeParse({ email: "" }).success).toBe(false);
  });

  const reset = { email: "ana@correo.com", code: "123456", newPassword: "nueva-clave-99", confirmPassword: "nueva-clave-99" };

  it("el código son exactamente 6 dígitos", () => {
    expect(resetPasswordSchema.safeParse(reset).success).toBe(true);
    for (const code of ["12345", "1234567", "12a456", ""]) {
      const parsed = resetPasswordSchema.safeParse({ ...reset, code });
      expect(parsed.success, code).toBe(false);
    }
  });

  it("la clave nueva se repite igual y tiene 8 o más caracteres", () => {
    expect(resetPasswordSchema.safeParse({ ...reset, confirmPassword: "otra" }).success).toBe(false);
    expect(resetPasswordSchema.safeParse({ ...reset, newPassword: "corta", confirmPassword: "corta" }).success).toBe(false);
  });
});
