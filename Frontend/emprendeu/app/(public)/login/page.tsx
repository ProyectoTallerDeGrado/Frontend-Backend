import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { getSession, LoginView } from "@/features/auth";

export const metadata: Metadata = { title: "Ingreso · CIE-U" };

export default async function LoginPage({ searchParams }: PageProps<"/login">) {
  if (await getSession()) redirect("/");
  const { registrado } = await searchParams;
  return <LoginView registered={registrado === "1"} />;
}
