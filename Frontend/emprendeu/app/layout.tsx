import type { Metadata } from "next";
import { DM_Sans, Sora } from "next/font/google";
import "./globals.css";
import { cn } from "@/lib/utils";

const dmSans = DM_Sans({
  subsets: ["latin"],
  variable: "--font-dm-sans",
});

const sora = Sora({
  subsets: ["latin"],
  variable: "--font-sora",
});

export const metadata: Metadata = {
  title: "CIE-U · Administración",
  description:
    "Panel de administración del Centro de Innovación y Emprendimiento Universitario.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="es"
      className={cn("h-full", "antialiased", "font-sans", dmSans.variable, sora.variable)}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
