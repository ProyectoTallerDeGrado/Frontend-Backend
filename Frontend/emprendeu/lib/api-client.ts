import "server-only";

import { headers } from "next/headers";

import { env } from "@/lib/env";

/** Error del contrato `{"error": {code, message, details}}` o de red (`status` 0). */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly details: unknown = null,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

type RequestOptions = {
  method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  /** JSON, o `FormData` para subir archivos (el navegador/Node fija el `boundary`). */
  body?: unknown;
  token?: string;
  /** Plazo de la petición; la carga de documentos (embeddings) necesita más que el normal. */
  timeoutMs?: number;
};

/**
 * IP de quien visita la web, para reenviarla al backend. Sin esto el backend ve la IP de este
 * servidor en todas las peticiones y sus límites por IP (login, recuperación, postulaciones)
 * bloquean a todo el mundo a la vez. Se toma la última de `x-forwarded-for`: la que puso el proxy
 * más cercano (o el propio Next, desde el socket, si no hay proxy delante).
 */
async function visitorIp(): Promise<string | undefined> {
  try {
    const forwarded = (await headers()).get("x-forwarded-for");
    return forwarded?.split(",").at(-1)?.trim() || undefined;
  } catch {
    // Fuera de una petición (build, tareas): no hay visitante.
    return undefined;
  }
}

/** Cliente HTTP del backend. Solo se usa desde el servidor (acciones y componentes de servidor). */
export async function apiFetch(path: string, options: RequestOptions = {}): Promise<unknown> {
  const { method = "GET", body, token, timeoutMs = 15_000 } = options;
  const isForm = body instanceof FormData;
  const ip = await visitorIp();
  let response: Response;
  try {
    response = await fetch(`${env.apiUrl}${path}`, {
      method,
      headers: {
        Accept: "application/json",
        ...(body !== undefined && !isForm ? { "Content-Type": "application/json" } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(ip ? { "X-Forwarded-For": ip } : {}),
      },
      body: body === undefined ? undefined : isForm ? body : JSON.stringify(body),
      cache: "no-store",
      signal: AbortSignal.timeout(timeoutMs),
    });
  } catch {
    throw new ApiError(0, "network_error", "No se pudo conectar con el servidor.");
  }

  const payload: unknown = await response.json().catch(() => null);
  if (!response.ok) {
    const error = (payload as { error?: { code?: string; message?: string; details?: unknown } } | null)
      ?.error;
    throw new ApiError(
      response.status,
      error?.code ?? "http_error",
      error?.message ?? `Error ${response.status}`,
      error?.details ?? null,
    );
  }
  return payload;
}
