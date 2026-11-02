import { readFileSync } from "node:fs";
import { join } from "node:path";

import { expect, test, type Page } from "@playwright/test";

type Person = { email: string; password: string; name: string };
const { stamp, people } = JSON.parse(readFileSync(join(__dirname, ".users.json"), "utf8")) as {
  stamp: number;
  people: Record<"admin" | "coordinador" | "asesor" | "emprendedor", Person>;
};

/** Avisos de error visibles (se descarta el anunciador de rutas de Next, que también es `role="alert"` pero va vacío). */
const alerts = (page: Page) => page.getByRole("alert").filter({ hasText: /\S/ });

/** Entra con una cuenta válida y espera a que la sesión esté lista (la acción redirige al inicio). */
async function signInOk(page: Page, person: Person) {
  await signIn(page, person);
  await expect(page).toHaveURL(/\/$/);
}

async function signIn(page: Page, person: Person) {
  await page.goto("/login");
  await page.getByLabel("Correo electrónico").fill(person.email);
  await page.getByLabel("Contraseña", { exact: true }).fill(person.password);
  await page.getByRole("button", { name: "Ingresar al panel" }).click();
}

test.describe("inicio de sesión", () => {
  test("sin sesión, el panel manda al login", async ({ page }) => {
    await page.goto("/users");
    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByRole("button", { name: "Ingresar al panel" })).toBeVisible();
  });

  test("una contraseña equivocada se explica y no deja entrar", async ({ page }) => {
    await signIn(page, { ...people.coordinador, password: "clave-equivocada-1" });
    await expect(alerts(page)).toBeVisible();
    await expect(page).toHaveURL(/\/login$/);
  });

  test("los campos vacíos se marcan antes de llamar al servidor", async ({ page }) => {
    await page.goto("/login");
    await page.getByRole("button", { name: "Ingresar al panel" }).click();
    await expect(page.getByText("Ingresa tu correo electrónico.")).toBeVisible();
    await expect(page.getByText("Ingresa tu contraseña.")).toBeVisible();
  });

  test("el emprendedor no entra al panel: usa la app móvil", async ({ page }) => {
    await signIn(page, people.emprendedor);
    await expect(page.getByText("usa la app móvil del CIE-U")).toBeVisible();
    await expect(page).toHaveURL(/\/login$/);
  });
});

test.describe("una pantalla por rol", () => {
  test("administrador: ve los usuarios y la configuración, y puede cerrar sesión", async ({ page }) => {
    await signInOk(page, people.admin);
    await page.goto("/users");
    await expect(page.getByRole("heading", { name: "Usuarios" })).toBeVisible();
    await expect(page.getByText(people.coordinador.email)).toBeVisible();
    await expect(page.getByRole("link", { name: "Roles y permisos" })).toBeVisible();
    await page.getByRole("button", { name: "Cerrar sesión" }).click();
    await expect(page).toHaveURL(/\/login$/);
    await page.goto("/users");
    await expect(page).toHaveURL(/\/login$/); // la sesión quedó cerrada
  });

  test("coordinación: gestiona la admisión y registra emprendedores, sin administrar usuarios", async ({ page }) => {
    await signInOk(page, people.coordinador);
    await page.goto("/admissions");
    await expect(page.getByRole("heading", { name: "Admisión" })).toBeVisible();
    await expect(page.getByRole("link", { name: "Pendientes" })).toBeVisible();
    await page.goto("/entrepreneurs");
    await expect(page.getByRole("button", { name: "Nuevo emprendedor" })).toBeVisible();
    await page.goto("/training");
    await expect(page.getByRole("button", { name: "Nueva capacitación" })).toBeVisible();
    // lo del administrador no está en su menú
    await expect(page.getByRole("link", { name: "Roles y permisos" })).toHaveCount(0);
    await page.goto("/users");
    await expect(page.getByText(people.admin.email)).toHaveCount(0);
  });

  test("asesor: consulta capacitaciones y emprendimientos sin poder crear ni asignar", async ({ page }) => {
    await signInOk(page, people.asesor);
    await page.goto("/training");
    await expect(page.getByRole("heading", { name: "Capacitaciones" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Nueva capacitación" })).toHaveCount(0);
    await page.goto("/ventures");
    await expect(page.getByRole("heading", { name: "Emprendimientos" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Nuevo emprendimiento" })).toHaveCount(0);
    await expect(page.getByRole("link", { name: "Asignaciones" })).toHaveCount(0); // es de coordinación
    await expect(page.getByRole("link", { name: "Mi disponibilidad" })).toBeVisible();
  });
});

test.describe("formulario público de postulación", () => {
  // Cada ejecución viaja con su propia IP: la web la reenvía a la API (`X-Forwarded-For`) y el límite
  // de intentos se cuenta por postulante, no por servidor web. Requiere APPLICATION_TRUST_FORWARDED_FOR=true.
  test.use({ extraHTTPHeaders: { "x-forwarded-for": `10.${(stamp >> 16) & 255}.${(stamp >> 8) & 255}.${stamp & 255}` } });

  test("se envía sin iniciar sesión y la coordinación la encuentra pendiente", async ({ page, browser }) => {
    const applicant = `postulante-e2e-${stamp}@correo.com`;
    await page.goto("/postular");
    await expect(page.getByRole("heading", { name: "Postúlate al programa" })).toBeVisible();

    // validación en el navegador antes de enviar
    await page.getByRole("button", { name: "Enviar postulación" }).click();
    await expect(page.getByText("Escribe tu nombre.")).toBeVisible();

    await page.getByLabel("Nombre", { exact: true }).fill("Lucía María");
    await page.getByLabel("Apellido").fill("Vargas");
    await page.getByLabel("Correo electrónico").fill(applicant);
    await page.getByLabel("Nombre de tu emprendimiento").fill(`Dulces E2E ${stamp}`);
    await page.getByLabel("Sector").fill("Alimentos");
    await page.getByRole("button", { name: "Enviar postulación" }).click();
    await expect(page.getByText("¡Recibimos tu postulación!")).toBeVisible();

    // enviarla otra vez con el mismo correo se explica (una pendiente por correo)
    await page.goto("/postular");
    await page.getByLabel("Nombre", { exact: true }).fill("Lucía María");
    await page.getByLabel("Apellido").fill("Vargas");
    await page.getByLabel("Correo electrónico").fill(applicant);
    await page.getByLabel("Nombre de tu emprendimiento").fill("Otro nombre");
    await page.getByRole("button", { name: "Enviar postulación" }).click();
    await expect(alerts(page)).toContainText("Ya recibimos una postulación con ese correo");

    // la coordinación la ve pendiente en el panel
    const coordinatorContext = await browser.newContext();
    const coordinator = await coordinatorContext.newPage();
    await signInOk(coordinator, people.coordinador);
    await coordinator.goto(`/admissions?q=${encodeURIComponent(`Dulces E2E ${stamp}`)}`);
    await expect(coordinator.getByText(applicant)).toBeVisible();
    await expect(coordinator.getByRole("button", { name: "Revisar" })).toBeVisible();
    await coordinatorContext.close();
  });

  test("el campo trampa no se ve ni se enfoca con el teclado", async ({ page }) => {
    await page.goto("/postular");
    const trap = page.locator('input[name="sitio_web"]');
    await expect(trap).toHaveAttribute("tabindex", "-1");
    await expect(trap).not.toBeInViewport();
  });
});
