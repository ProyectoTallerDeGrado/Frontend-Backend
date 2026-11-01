import "server-only";

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
  body?: unknown;
  token?: string;
};

/** Cliente HTTP del backend. Solo se usa desde el servidor (acciones y componentes de servidor). */
export async function apiFetch(path: string, options: RequestOptions = {}): Promise<unknown> {
  const { method = "GET", body, token } = options;
  let response: Response;
  try {
    response = await fetch(`${env.apiUrl}${path}`, {
      method,
      headers: {
        Accept: "application/json",
        ...(body !== undefined ? { "Content-Type": "application/json" } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
      cache: "no-store",
      signal: AbortSignal.timeout(15_000),
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
