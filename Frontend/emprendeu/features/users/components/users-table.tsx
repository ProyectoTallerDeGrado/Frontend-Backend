import { formatWhen, initials } from "@/lib/format";

import { AVATAR_COLORS } from "../roles";
import type { Role, User } from "../types";
import { UserRoleControl, UserStatusSwitch } from "./user-row-controls";

type UsersTableProps = {
  users: User[];
  roles: Role[];
  currentUserId: number;
  canToggle: boolean;
  canChangeRole: boolean;
};

const COLS = "grid-cols-[minmax(240px,2.2fr)_190px_220px_150px]";

export function UsersTable({ users, roles, currentUserId, canToggle, canChangeRole }: UsersTableProps) {
  return (
    <div className="overflow-x-auto overflow-y-hidden rounded-2xl border border-border bg-card">
      <div className="min-w-[900px]">
        <div
          className={`grid ${COLS} gap-4 border-b border-border bg-[#f8fafe] px-6 py-3.5 text-[13px] font-bold tracking-[.04em] text-muted-foreground uppercase`}
        >
          <span>Usuario</span>
          <span>Rol</span>
          <span>Estado de la cuenta</span>
          <span>Último acceso</span>
        </div>
        {users.map((u, i) => {
          const [bg, fg] = AVATAR_COLORS[u.usuario_id % AVATAR_COLORS.length];
          const name = `${u.nombre} ${u.apellido}`;
          return (
            <div
              key={u.usuario_id}
              className={`grid ${COLS} animate-[fade-up_.45s_ease_both] items-center gap-4 border-b border-[#eef2fa] px-6 py-3 transition-colors hover:bg-[#f4f7ff]`}
              style={{ animationDelay: `${Math.min(i, 10) * 45}ms` }}
            >
              <div className="flex min-w-0 items-center gap-3.5">
                <div
                  aria-hidden="true"
                  className="flex size-[42px] shrink-0 items-center justify-center rounded-full text-sm font-bold"
                  style={{ background: bg, color: fg }}
                >
                  {initials(name)}
                </div>
                <div className="min-w-0">
                  <div className="truncate text-[15px] font-semibold">{name}</div>
                  <div className="truncate text-[13px] text-muted-foreground">{u.email}</div>
                </div>
              </div>
              <div>
                <UserRoleControl
                  userId={u.usuario_id}
                  name={name}
                  role={u.rol}
                  roles={roles}
                  editable={canChangeRole && u.usuario_id !== currentUserId}
                />
              </div>
              <UserStatusSwitch
                userId={u.usuario_id}
                name={name}
                enabled={u.estado !== "deshabilitada"}
                locked={!canToggle || u.usuario_id === currentUserId}
              />
              <div className="text-sm text-muted-foreground">{formatWhen(u.ultimo_acceso)}</div>
            </div>
          );
        })}
        {users.length === 0 && (
          <div className="px-6 py-10 text-center text-[15px] text-muted-foreground">
            Ningún usuario coincide con la búsqueda.
          </div>
        )}
      </div>
    </div>
  );
}
