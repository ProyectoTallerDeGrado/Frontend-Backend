# Análisis funcional de EmprendeU (base del manual de usuario)

Fecha: 2026-11-18. Estado: **V** verificado (ejecutado y capturado), **I** inferido del código, **P** pendiente de comprobación.

## Fuentes
- Código: `Frontend/emprendeu` (web Next.js), `Frontend/app_emprendeu` (Flutter), `Backend/EmprendeU` (FastAPI).
- Documentos: `AGENTS.md`, `doc/chatbot-y-tutorial.md`, `doc/notificaciones-push.md`, `Backend/EmprendeU/database/SEED.md`.
- Ejecución: backend en Docker (datos demo), web en `pnpm dev`, app móvil en un teléfono Android arm64.

## Roles y permisos
Roles: administrador, coordinador, asesor, emprendedor. Matriz inicial en `Backend/.../migrations/versions/7a1c4f2b9d30_semilla_roles_y_permisos.py`; editable en `/roles`. El panel web rechaza al emprendedor; la app móvil rechaza al personal. Comprobado: V para menús por rol (admin, coordinador, asesor).

## Matriz funcional

| Módulo | Funcionalidad | Rol | Ruta / pantalla | Archivos clave | Estado |
|---|---|---|---|---|---|
| Acceso | Inicio de sesión web | Personal | `/login` | `features/auth/schemas/auth-schemas.ts`, `server/actions.ts` | V |
| Acceso | Inicio de sesión móvil | Emprendedor | `/login` (app) | `lib/features/auth/.../login_screen.dart` | V |
| Acceso | Registro de cuenta | Público | `/register`, `/register` (app) | `auth-schemas.ts`, `register_screen.dart` | V (web); I (móvil) |
| Acceso | Recuperación de contraseña (código de 6 dígitos) | Todos | `/forgot-password`, `/reset-password` | `password_reset_usecases.dart` | V (pantalla); P (envío de correo) |
| Acceso | Postulación pública | Público | `/apply` | `features/entrepreneurs` | V (pantalla); P (envío) |
| Inicio | Resumen | Admin/Coord | `/panel` | `features/indicators/.../overview-view.tsx` | V |
| Inicio | Indicadores | Admin/Coord | `/dashboard` | `dashboard-screen.tsx` | V |
| Inicio | Reportes, exportar CSV/Excel | Admin/Coord | `/reports` | `reports/export/route.ts` | V (pantalla); P (descarga) |
| Programa | Admisiones | Coord | `/admissions`, `/admissions/[id]` | `admissions-screen.tsx` | V (lectura); I (decisión) |
| Programa | Emprendedores (alta) | Coord | `/entrepreneurs` | `features/entrepreneurs` | V (lista); I (alta) |
| Programa | Emprendimientos (crear, editar, equipo, etapa) | Coord | `/ventures` | `features/ventures/components/*` | V (lista); I (formularios) |
| Programa | Ficha: progreso, seguimiento, etapas, documentos, historial | Staff | `/ventures/[id]/*` | `app/(app)/ventures/[id]` | V |
| Programa | Necesidades | Staff | `/needs` | `features/needs` | V |
| Programa | Alertas | Staff | `/alerts`, `/alerts/[id]` | `features/alerts` | V |
| Programa | Salud | Staff | `/health` | `features/indicators` | V |
| Acompañamiento | Asignaciones | Coord | `/mentoring/assignments` | `features/mentoring` | V |
| Acompañamiento | Mi disponibilidad | Asesor | `/mentoring/availability` | `features/mentoring` | V |
| Acompañamiento | Sesiones, recomendaciones, compromisos | Staff | `/mentoring/sessions` | `session-forms.tsx` | V (lista); I (formularios) |
| Acompañamiento | Capacitaciones | Staff | `/training`, `/training/[id]` | `features/training` | V |
| Configuración | Usuarios | Admin | `/users` | `features/users` | V |
| Configuración | Roles y permisos | Admin | `/roles` | `features/users/roles.ts` | V |
| Configuración | Parámetros de seguimiento | Admin/Coord | `/settings/tracking` | `tracking-form.tsx` | V |
| Configuración | Catálogos y XP | Admin/Coord | `/catalogs` | `features/gamification` | V |
| Configuración | Base de conocimiento | Admin/Coord | `/knowledge` | `features/ai_assistant` | V (pantalla, servicio IA caído); P (subida) |
| Configuración | Auditoría y exportación CSV | Admin/Coord | `/audit` | `features/audit` | V |
| Cuenta | Mi cuenta, cambio de contraseña | Staff | `/account` | `features/auth` | V |
| Ayuda | Tutorial guiado | Staff | primer ingreso | `components/tour/*` | V |
| Ayuda | Asistente de ayuda | Staff | botón flotante | `help-chat.tsx` | V (apertura); P (respuesta IA) |
| Móvil | Inicio, compromisos, avances | Emprendedor | `/home` | `features/home`, `mentoring` | V (Inicio); I (acciones) |
| Móvil | Camino, retos | Emprendedor | `/journey` | `features/gamification` | V (lectura); I (cumplir reto) |
| Móvil | Mentorías: agendar, cancelar, historial, tareas | Emprendedor | `/mentoring/*` | `features/mentoring` | V (pantallas); I (agendar/cancelar) |
| Móvil | Coach IA y IA local | Emprendedor | `/coach`, Perfil | `features/ai_assistant` | V (pantalla); P (respuestas) |
| Móvil | Perfil, editar emprendimiento, hitos | Emprendedor | `/account`, `/venture/*` | `features/ventures`, `auth` | V (Perfil); I (formularios) |
| Móvil | Necesidades, documentos, capacitaciones, notificaciones | Emprendedor | `/venture/needs`, `/venture/documents`, `/training`, `/notifications` | `features/needs`, `documents`, `training`, `notifications` | V (pantallas); I (acciones) |
| Móvil | Trabajo sin conexión | Emprendedor | — | `mentoring_local_data_source.dart` | I |
| Móvil | Notificaciones push | Emprendedor | — | `push_gate.dart` | P (falta `google-services.json`) |
