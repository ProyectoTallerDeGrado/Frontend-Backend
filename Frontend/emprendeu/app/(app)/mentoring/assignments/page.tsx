import type { Metadata } from "next";

import { AssignmentsScreen } from "@/features/mentoring";

export const metadata: Metadata = { title: "Asignaciones · CIE-U" };

export default function AssignmentsPage() {
  return <AssignmentsScreen />;
}
