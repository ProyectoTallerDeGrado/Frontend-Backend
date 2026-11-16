import { expect, test } from "@playwright/test";

const PASSWORD = "Demo12345!";

async function login(page: import("@playwright/test").Page, email: string, password = PASSWORD) {
  await page.goto("/login");
  await page.getByLabel("Correo electrónico").fill(email);
  await page.getByLabel("Contraseña", { exact: true }).fill(password);
  await page.getByRole("button", { name: /Ingresar al panel/ }).click();
}

/** Inicia sesión y espera a llegar al panel (el login redirige a /panel). */
async function loginOk(page: import("@playwright/test").Page, email: string) {
  await login(page, email);
  await page.waitForURL("**/panel");
}

test.describe("inicio de sesión (CU01)", () => {
  test("sin sesión, una ruta privada manda al login", async ({ page }) => {
    await page.goto("/users");
    await expect(page).toHaveURL(/\/login$/);
  });

  test("un acceso correcto entra al panel", async ({ page }) => {
    await loginOk(page, "coordinador@emprendeu.bo");
    await expect(page).toHaveURL(/\/panel$/);
  });

  test("una contraseña incorrecta se explica y no entra", async ({ page }) => {
    await login(page, "coordinador@emprendeu.bo", "incorrecta-123");
    await expect(page.locator(`p[role="alert"]`)).toContainText("Correo o contraseña incorrectos");
    await expect(page).toHaveURL(/\/login$/);
  });

  test("una cuenta de emprendedor se redirige a la app móvil", async ({ page }) => {
    await login(page, "emprendedor@emprendeu.bo");
    await expect(page.locator(`p[role="alert"]`)).toContainText("app móvil");
  });

  test("el enlace de recuperación lleva al formulario y al paso del código", async ({ page }) => {
    await page.goto("/login");
    await page.getByRole("link", { name: "¿Olvidaste tu contraseña?" }).click();
    await expect(page).toHaveURL(/\/forgot-password$/);

    // Un correo vacío se valida antes de llamar al servidor.
    await page.getByRole("button", { name: "Enviar código" }).click();
    await expect(page.getByText("Ingresa tu correo electrónico.")).toBeVisible();

    // La respuesta es la misma aunque la cuenta no exista (no revela usuarios). Un correo
    // distinto por ejecución: el backend limita las solicitudes por correo (3 cada 15 min).
    const email = `nadie.${Date.now()}@emprendeu.bo`;
    await page.getByLabel("Correo electrónico").fill(email);
    await page.getByRole("button", { name: "Enviar código" }).click();
    await expect(page).toHaveURL(/\/reset-password\?email=.+&enviado=1$/, { timeout: 30_000 });
    await expect(page.getByText("Si el correo está registrado")).toBeVisible();

    // Un código con letras no llega al servidor.
    await page.getByLabel("Código de 6 dígitos").fill("12ab");
    await page.getByLabel("Contraseña nueva").fill("nueva-clave-99");
    await page.getByLabel("Confirmar contraseña").fill("nueva-clave-99");
    await page.getByRole("button", { name: "Restablecer contraseña" }).click();
    await expect(page.getByText("El código tiene 6 dígitos.")).toBeVisible();

    // Un código de 6 dígitos que no existe lo rechaza el servidor. (React limpia el
    // formulario tras cada envío, así que se vuelve a llenar completo.)
    await page.getByLabel("Código de 6 dígitos").fill("000000");
    await page.getByLabel("Contraseña nueva").fill("nueva-clave-99");
    await page.getByLabel("Confirmar contraseña").fill("nueva-clave-99");
    await page.getByRole("button", { name: "Restablecer contraseña" }).click();
    await expect(page.getByText("El código no es válido o ya venció")).toBeVisible({ timeout: 15_000 });
  });
});

test.describe("una pantalla por rol", () => {
  test("administrador: Usuarios", async ({ page }) => {
    await loginOk(page, "admin@emprendeu.bo");
    await page.goto("/users");
    await expect(page.getByRole("heading", { name: "Usuarios" })).toBeVisible();
    await expect(page.getByText("coordinador@emprendeu.bo")).toBeVisible();
  });

  test("coordinador: Emprendimientos y la pestaña de documentos de uno", async ({ page }) => {
    await loginOk(page, "coordinador@emprendeu.bo");
    await page.goto("/ventures");
    await expect(page.getByRole("heading", { name: "Emprendimientos" })).toBeVisible();
    await page.getByRole("link", { name: /Café Altiplano/ }).click();
    await page.getByRole("link", { name: "Documentos" }).click();
    // La primera visita compila la ruta en modo desarrollo: se le da más margen.
    await expect(page).toHaveURL(/\/ventures\/\d+\/documents$/, { timeout: 30_000 });
    await expect(page.getByRole("heading", { name: /Documentos/ })).toBeVisible();
    await expect(page.getByRole("button", { name: /Subir documento/ })).toBeVisible();
  });

  test("coordinador: Capacitaciones", async ({ page }) => {
    await loginOk(page, "coordinador@emprendeu.bo");
    await page.goto("/training");
    await expect(page.getByRole("heading", { name: "Capacitaciones" })).toBeVisible();
    await expect(page.getByRole("button", { name: /Nueva capacitación/ })).toBeVisible();
  });

  test("coordinador: Reportes ofrece Excel y CSV", async ({ page }) => {
    await loginOk(page, "coordinador@emprendeu.bo");
    await page.goto("/reports");
    await expect(page.getByRole("link", { name: "Exportar Excel" })).toBeVisible();
    await expect(page.getByRole("link", { name: "Exportar CSV" })).toBeVisible();
  });

  test("asesor: Mi disponibilidad", async ({ page }) => {
    await loginOk(page, "asesor@emprendeu.bo");
    await page.goto("/mentoring/availability");
    await expect(page.getByRole("heading", { name: "Mi disponibilidad" })).toBeVisible();
  });

  test("asesor: no ve la administración de usuarios", async ({ page }) => {
    await loginOk(page, "asesor@emprendeu.bo");
    await page.goto("/users");
    await expect(page.getByRole("heading", { name: "Sin acceso a Usuarios" })).toBeVisible();
  });
});
