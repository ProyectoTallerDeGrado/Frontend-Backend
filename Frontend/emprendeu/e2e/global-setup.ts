import { writeFileSync } from "node:fs";
import { join } from "node:path";

const API = process.env.E2E_API_URL ?? "http://127.0.0.1:8000/api/v1";
const PASSWORD = "clave-e2e-12345";

type Json = Record<string, unknown>;

async function call(path: string, init: RequestInit & { token?: string; json?: unknown } = {}): Promise<Json> {
  const { token, json, ...rest } = init;
  const response = await fetch(`${API}${path}`, {
    ...rest,
    headers: {
      ...(json !== undefined ? { "Content-Type": "application/json" } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: json !== undefined ? JSON.stringify(json) : undefined,
  });
  const body = (await response.json().catch(() => ({}))) as Json;
  if (!response.ok) throw new Error(`${init.method ?? "GET"} ${path} -> ${response.status} ${JSON.stringify(body)}`);
  return body;
}

/** Crea una persona de cada rol (con un sufijo único) y deja sus credenciales en `e2e/.users.json`. */
export default async function globalSetup() {
  const email = process.env.E2E_ADMIN_EMAIL;
  const password = process.env.E2E_ADMIN_PASSWORD;
  if (!email || !password) {
    throw new Error("Define E2E_ADMIN_EMAIL y E2E_ADMIN_PASSWORD (una cuenta de administrador existente).");
  }
  const login = await call("/auth/login", { method: "POST", json: { email, password } });
  const token = String(login.access_token);
  const stamp = Date.now();
  const people = {
    admin: { email, password, name: "Administrador" },
    coordinador: { email: `coord-e2e-${stamp}@prueba.com`, password: PASSWORD, name: "Coordinadora E2E" },
    asesor: { email: `asesor-e2e-${stamp}@prueba.com`, password: PASSWORD, name: "Asesor E2E" },
    emprendedor: { email: `emp-e2e-${stamp}@prueba.com`, password: PASSWORD, name: "Emprendedora E2E" },
  };
  for (const [rol, p] of Object.entries(people)) {
    if (rol === "admin") continue;
    await call("/users", { method: "POST", token, json: { nombre_completo: p.name, email: p.email, rol: rol, password: p.password } });
  }
  writeFileSync(join(__dirname, ".users.json"), JSON.stringify({ stamp, people }, null, 2));
}
