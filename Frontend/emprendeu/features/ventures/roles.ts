import type { MemberRole } from "./schemas/ventures-schemas";

// Sin "use client": lo usan tanto Server Components como Client Components.
export const ROLE_LABELS: Record<MemberRole, string> = {
  fundador: "Fundador",
  cofundador: "Cofundador",
  miembro: "Miembro",
};

export function roleLabel(role: string | null): string {
  return role && role in ROLE_LABELS ? ROLE_LABELS[role as MemberRole] : (role ?? "Integrante");
}
