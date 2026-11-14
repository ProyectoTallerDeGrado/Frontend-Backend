import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { getSession, RegisterView } from "@/features/auth";

export const metadata: Metadata = { title: "Registro · CIE-U" };

export default async function RegisterPage() {
  if (await getSession()) redirect("/panel");
  return <RegisterView />;
}
