import { Pagination } from "@/components/layout/pagination";

import { USERS_PAGE_SIZE, listUsers } from "../server/queries";
import { UserFilters } from "./user-filters";
import { UsersTable } from "./users-table";

type UsersViewProps = {
  q: string;
  rol: string;
  page: number;
  currentUserId: number;
  canToggle: boolean;
  canChangeRole: boolean;
};

export async function UsersView({ q, rol, page, currentUserId, canToggle, canChangeRole }: UsersViewProps) {
  const data = await listUsers({ q, rol, page });
  const hrefFor = (p: number) => {
    const params = new URLSearchParams();
    if (q) params.set("q", q);
    if (rol) params.set("rol", rol);
    if (p > 1) params.set("page", String(p));
    const query = params.toString();
    return query ? `/users?${query}` : "/users";
  };
  return (
    <div className="flex flex-col gap-[18px]">
      <UserFilters q={q} rol={rol} />
      <UsersTable
        users={data.items}
        currentUserId={currentUserId}
        canToggle={canToggle}
        canChangeRole={canChangeRole}
      />
      <Pagination page={data.page} pageSize={USERS_PAGE_SIZE} total={data.total} hrefFor={hrefFor} />
      <p className="text-[13px] text-muted-foreground">
        Los cambios de estado y de rol quedan registrados en la auditoría. No puedes deshabilitar ni cambiar el
        rol de tu propia cuenta.
      </p>
    </div>
  );
}
