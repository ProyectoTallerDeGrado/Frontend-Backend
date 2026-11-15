import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { getSession, ResetPasswordView } from "@/features/auth";

export const metadata: Metadata = { title: "Nueva contraseña · CIE-U" };

export default async function ResetPasswordPage({ searchParams }: PageProps<"/reset-password">) {
  if (await getSession()) redirect("/panel");
  const { email, enviado } = await searchParams;
  return <ResetPasswordView email={typeof email === "string" ? email : ""} sent={enviado === "1"} />;
}
