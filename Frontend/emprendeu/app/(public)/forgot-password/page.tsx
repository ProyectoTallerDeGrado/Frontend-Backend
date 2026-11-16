import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { ForgotPasswordView, getSession } from "@/features/auth";

export const metadata: Metadata = { title: "Recuperar contraseña · CIE-U" };

export default async function ForgotPasswordPage() {
  if (await getSession()) redirect("/panel");
  return <ForgotPasswordView />;
}
