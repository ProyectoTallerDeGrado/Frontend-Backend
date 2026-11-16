import { expect, test } from "@playwright/test";

/** La portada pública no necesita sesión ni datos del backend. */
test.describe("landing pública", () => {
  test("muestra el titular y lleva a la postulación", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("heading", { level: 1 })).toContainText("Tu idea no debería morir en un cuaderno.");
    await page.getByRole("link", { name: "Postula tu emprendimiento" }).first().click();
    await expect(page).toHaveURL(/\/apply$/);
    await expect(page.getByRole("heading", { level: 1 })).toContainText("Postula tu emprendimiento");
    await page.getByRole("link", { name: "Volver al inicio", exact: true }).click();
    await expect(page).toHaveURL(/\/$/);
  });

  test("las preguntas frecuentes se abren", async ({ page }) => {
    await page.goto("/");
    const question = page.getByText("¿Puedo postular con mi equipo?");
    await question.scrollIntoViewIfNeeded();
    await question.click();
    await expect(page.getByText("Un emprendimiento puede tener varios integrantes")).toBeVisible();
  });

  test("con «reducir movimiento» el contenido se ve sin animaciones", async ({ browser }) => {
    const context = await browser.newContext({ reducedMotion: "reduce" });
    const page = await context.newPage();
    await page.goto("/");
    // La escena fijada no se monta: queda la lista legible de problema → respuesta.
    await expect(page.getByText("Un asesor asignado que te acompaña").first()).toBeVisible();
    await expect(page.getByRole("button", { name: /animaciones/ })).toBeHidden();
    await context.close();
  });

  test("en móvil el menú abre las secciones y no hay desborde horizontal", async ({ browser }) => {
    const context = await browser.newContext({ viewport: { width: 360, height: 740 } });
    const page = await context.newPage();
    await page.goto("/");
    await page.getByRole("button", { name: "Abrir menú" }).click();
    await page.getByRole("navigation", { name: "Secciones" }).getByRole("link", { name: "Preguntas" }).click();
    await expect(page).toHaveURL(/#preguntas$/);
    await expect(page.getByRole("button", { name: "Abrir menú" })).toBeVisible();
    expect(await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth)).toBeLessThanOrEqual(0);
    await context.close();
  });

  test("los metadatos públicos responden sin sesión", async ({ request }) => {
    for (const path of ["/robots.txt", "/sitemap.xml", "/opengraph-image", "/icon.png"]) {
      expect((await request.get(path, { maxRedirects: 0 })).status(), path).toBe(200);
    }
  });
});
