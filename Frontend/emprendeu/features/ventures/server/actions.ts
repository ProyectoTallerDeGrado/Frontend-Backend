"use server";

import { revalidatePath } from "next/cache";

import { ApiError } from "@/lib/api-client";
import { authedFetch } from "@/features/auth";

import { MEMBER_ROLES, teamSchema, ventureFormSchema, type MemberRole } from "../schemas/ventures-schemas";

export async function setStageStateAction(
  etapaId: number,
  estado: "activa" | "inactiva",
  name: string,
): Promise<{ ok: boolean; message: string }> {
  try {
    await authedFetch(`/stages/${etapaId}`, { method: "PATCH", body: { estado } });
  } catch (error) {
    const denied = error instanceof ApiError && error.status === 403;
    return { ok: false, message: denied ? "No tienes permiso para esta acción." : "No se pudo actualizar la etapa." };
  }
  revalidatePath("/catalogs");
  return { ok: true, message: `Etapa ${estado === "activa" ? "activada" : "desactivada"}: ${name}.` };
}

/** CU12: avanza el emprendimiento a la etapa siguiente (el backend rechaza saltos y retrocesos). */
export async function advanceVentureStageAction(
  ventureId: number,
  stageId: number,
  observaciones: string,
  name: string,
): Promise<{ ok: boolean; message: string }> {
  try {
    await authedFetch(`/ventures/${ventureId}/stage`, {
      method: "PUT",
      body: { etapa_id: stageId, observaciones: observaciones.trim() || null },
    });
  } catch (error) {
    if (error instanceof ApiError) {
      if (error.code === "invalid_stage_transition") return { ok: false, message: error.message };
      if (error.code === "stage_inactive") return { ok: false, message: "Esa etapa está inactiva." };
      if (error.status === 403) return { ok: false, message: "No tienes permiso para cambiar la etapa." };
    }
    return { ok: false, message: "No se pudo cambiar la etapa. Intenta de nuevo." };
  }
  revalidatePath("/ventures");
  return { ok: true, message: `Etapa actualizada: ${name}. Registrado en auditoría.` };
}

type VentureInput = {
  name: string;
  description: string;
  sector: string;
  estado: string;
};

export type TeamMemberInput = { entrepreneurId: number; role: MemberRole };

function ventureMessage(error: unknown, fallback: string): string {
  if (error instanceof ApiError) {
    if (error.code === "entrepreneur_required") return "Agrega al menos un emprendedor al equipo.";
    if (error.code === "entrepreneur_not_found") return "Uno de los emprendedores elegidos ya no existe.";
    if (error.code === "duplicate_member") return "Un emprendedor aparece dos veces en el equipo.";
    if (error.code === "already_member") return "Ese emprendedor ya es parte del equipo.";
    if (error.code === "member_not_found") return "Ese emprendedor ya no es parte del equipo.";
    if (error.code === "last_member") return "El emprendimiento debe quedar con al menos un integrante.";
    if (error.code === "reserved_fields") return "Ese campo solo lo cambia la coordinación.";
    if (error.status === 403) return "No tienes permiso para esta acción.";
  }
  return fallback;
}

/** CU05: la coordinación crea el emprendimiento con su equipo (uno o más emprendedores). */
export async function createVentureAction(
  input: VentureInput,
  team: TeamMemberInput[],
): Promise<{ ok: boolean; message: string }> {
  const parsed = ventureFormSchema.safeParse(input);
  if (!parsed.success) return { ok: false, message: parsed.error.issues[0]?.message ?? "Revisa los datos." };
  const members = teamSchema.safeParse(team);
  if (!members.success) return { ok: false, message: members.error.issues[0]?.message ?? "Revisa el equipo." };
  try {
    await authedFetch("/ventures", {
      method: "POST",
      body: {
        nombre: parsed.data.name,
        descripcion: parsed.data.description || null,
        sector: parsed.data.sector || null,
        integrantes: members.data.map((m) => ({ emprendedor_id: m.entrepreneurId, rol_en_emprendimiento: m.role })),
      },
    });
  } catch (error) {
    return { ok: false, message: ventureMessage(error, "No se pudo crear el emprendimiento. Intenta de nuevo.") };
  }
  revalidatePath("/ventures");
  return { ok: true, message: `Emprendimiento creado: ${parsed.data.name}.` };
}

/** CU05: edita los datos del emprendimiento; el estado es un campo reservado a la coordinación. */
export async function updateVentureAction(
  ventureId: number,
  input: VentureInput,
): Promise<{ ok: boolean; message: string }> {
  const parsed = ventureFormSchema.safeParse(input);
  if (!parsed.success) return { ok: false, message: parsed.error.issues[0]?.message ?? "Revisa los datos." };
  try {
    await authedFetch(`/ventures/${ventureId}`, {
      method: "PATCH",
      body: {
        nombre: parsed.data.name,
        descripcion: parsed.data.description || null,
        sector: parsed.data.sector || null,
        estado: parsed.data.estado || undefined,
      },
    });
  } catch (error) {
    return { ok: false, message: ventureMessage(error, "No se pudo guardar. Intenta de nuevo.") };
  }
  revalidatePath("/ventures");
  return { ok: true, message: `Emprendimiento actualizado: ${parsed.data.name}.` };
}

/** CU05: suma un emprendedor al equipo del emprendimiento. */
export async function addVentureMemberAction(
  ventureId: number,
  entrepreneurId: number | null,
  role: string,
): Promise<{ ok: boolean; message: string }> {
  if (!entrepreneurId) return { ok: false, message: "Elige al emprendedor." };
  if (!(MEMBER_ROLES as readonly string[]).includes(role)) return { ok: false, message: "Elige un rol válido." };
  try {
    await authedFetch(`/ventures/${ventureId}/members`, {
      method: "POST",
      body: { emprendedor_id: entrepreneurId, rol_en_emprendimiento: role },
    });
  } catch (error) {
    return { ok: false, message: ventureMessage(error, "No se pudo agregar al integrante. Intenta de nuevo.") };
  }
  revalidatePath("/ventures");
  return { ok: true, message: "Integrante agregado. Registrado en auditoría." };
}

/** CU05: quita a un emprendedor del equipo (el backend impide dejarlo vacío). */
export async function removeVentureMemberAction(
  ventureId: number,
  entrepreneurId: number,
  name: string,
): Promise<{ ok: boolean; message: string }> {
  try {
    await authedFetch(`/ventures/${ventureId}/members/${entrepreneurId}`, { method: "DELETE" });
  } catch (error) {
    return { ok: false, message: ventureMessage(error, "No se pudo quitar al integrante. Intenta de nuevo.") };
  }
  revalidatePath("/ventures");
  return { ok: true, message: `${name} ya no es parte del equipo.` };
}

/** CU24: marca una necesidad o dificultad como resuelta (queda en auditoría). */
export async function resolveNeedAction(rowId: number, name: string): Promise<{ ok: boolean; message: string }> {
  try {
    await authedFetch(`/venture-needs/${rowId}/resolve`, { method: "PATCH" });
  } catch (error) {
    if (error instanceof ApiError && error.status === 403) {
      return { ok: false, message: "No tienes permiso para resolver esta necesidad." };
    }
    return { ok: false, message: "No se pudo marcar como resuelta. Intenta de nuevo." };
  }
  revalidatePath("/needs");
  return { ok: true, message: `Resuelta: ${name}. Registrado en auditoría.` };
}
