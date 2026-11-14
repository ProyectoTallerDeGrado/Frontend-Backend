import { NextResponse, type NextRequest } from "next/server";

const SESSION_COOKIE = "emprendeu_session";
const PUBLIC_PATHS = ["/login", "/register", "/apply"];
/** Rutas públicas exactas: `/` es la landing. */
const PUBLIC_EXACT = ["/"];

/**
 * Primera barrera: sin cookie de sesión no se entra a rutas privadas.
 * La validez del token la comprueba `requireSession()` en el layout de `(app)`.
 */
export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const isPublic =
    PUBLIC_EXACT.includes(pathname) ||
    PUBLIC_PATHS.some((p) => pathname === p || pathname.startsWith(`${p}/`));
  if (!isPublic && !request.cookies.has(SESSION_COOKIE)) {
    return NextResponse.redirect(new URL("/login", request.url));
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|brand/).*)"],
};
