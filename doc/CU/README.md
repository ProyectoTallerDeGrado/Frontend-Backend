# Casos de uso de EmprendeU

Cada carpeta documenta un caso de uso **ya iniciado**: qué se hizo, dónde está en el código,
por qué se hizo así, cómo se verificó y qué falta. Los casos que aún no se empezaron no
tienen carpeta.

Estado revisado el **2026-11-13** contra el código de `main`. Ese día se ejecutaron las suites:

- Backend: `uv run pytest -q` → **101 passed** (PostgreSQL con pgvector).
- Móvil: `flutter test` → **125 passed, 4 skipped** (las pruebas de integración opt-in).
- Web: `pnpm lint`, `tsc` y `pnpm build` sin errores; no tiene pruebas automatizadas todavía (fase 7 del plan).

> «Completado» aquí significa: endpoint con prueba automatizada que pasa y pantalla en el
> cliente que le toca (regla de alcance: web para el personal, app para el emprendedor).
> El cuarto criterio del plan, el flujo de punta a punta **probado a mano**, no se verificó
> al escribir estos documentos.

| CU | Caso de uso | Prioridad | Cliente | Estado |
|---|---|---|---|---|
| [CU01](<CU01 Iniciar Sesion/README.md>) | Iniciar Sesión | Alta | Web y app | ✅ Completado |
| [CU02](<CU02 Gestionar Usuarios/README.md>) | Gestionar Usuarios | Alta | Web | ✅ Completado |
| [CU03](<CU03 Gestionar Roles y Permisos/README.md>) | Gestionar Roles y Permisos | Alta | Web | ✅ Completado |
| [CU04](<CU04 Registrar Emprendedor/README.md>) | Registrar Emprendedor | Alta | Web | ✅ Completado |
| [CU05](<CU05 Gestionar Emprendimiento/README.md>) | Gestionar Emprendimiento | Alta | Web y app | ✅ Completado (con equipo) |
| [CU06](<CU06 Visualizar Progreso Gamificado/README.md>) | Visualizar Progreso Gamificado | Alta | Web y app | ✅ Completado |
| [CU07](<CU07 Registrar Cumplimiento de Reto/README.md>) | Registrar Cumplimiento de Reto | Media | App | ✅ Completado |
| [CU08](<CU08 Consultar Puntos de Experiencia e Insignias/README.md>) | Consultar Puntos de Experiencia e Insignias | Media | App | ✅ Completado |
| [CU09](<CU09 Asignar Asesor Mentor/README.md>) | Asignar Asesor/Mentor | Alta | Web | ✅ Completado |
| [CU10](<CU10 Agendar Mentoria/README.md>) | Agendar Mentoría | Alta | App | ✅ Completado |
| [CU11](<CU11 Consultar Asistente Virtual/README.md>) | Consultar Asistente Virtual | Alta | App (+ web) | ✅ Completado |
| [CU12](<CU12 Gestionar Etapa del Emprendimiento/README.md>) | Gestionar Etapa del Emprendimiento | Alta | Web | ✅ Completado |
| [CU13](<CU13 Gestionar Alertas de Seguimiento/README.md>) | Gestionar Alertas de Seguimiento | Alta | Web | ✅ Completado |
| [CU14](<CU14 Visualizar Dashboard Ejecutivo/README.md>) | Visualizar Dashboard Ejecutivo | Alta | Web | ✅ Completado |
| [CU15](<CU15 Gestionar Disponibilidad de Mentor/README.md>) | Gestionar Disponibilidad de Mentor | Media | Web | ✅ Completado |
| [CU16](<CU16 Registrar Sesion de Acompanamiento/README.md>) | Registrar Sesión de Acompañamiento | Alta | Web | ✅ Completado |
| [CU17](<CU17 Registrar Recomendaciones/README.md>) | Registrar Recomendaciones | Alta | Web | ✅ Completado |
| [CU18](<CU18 Registrar Compromisos/README.md>) | Registrar Compromisos | Alta | Web | ✅ Completado |
| [CU19](<CU19 Consultar Historial del Emprendimiento/README.md>) | Consultar Historial del Emprendimiento | Alta | Web y app | ✅ Completado |
| [CU20](<CU20 Registrar Avances e Hitos/README.md>) | Registrar Avances e Hitos | Alta | App | ✅ Completado |
| [CU21](<CU21 Generar Reportes/README.md>) | Generar Reportes | Media | Web | ✅ Completado |
| [CU22](<CU22 Consultar Tareas y Compromisos Pendientes/README.md>) | Consultar Tareas y Compromisos Pendientes | Media | App | ✅ Completado |
| [CU23](<CU23 Consultar Mentorias Programadas/README.md>) | Consultar Mentorías Programadas | Media | Web y app | ✅ Completado |
| [CU24](<CU24 Registrar Necesidades y Dificultades/README.md>) | Registrar Necesidades y Dificultades | Media | App (+ web) | ✅ Completado |
| [CU25](<CU25 Configurar Parametros de Seguimiento/README.md>) | Configurar Parámetros de Seguimiento | Baja | Web | ✅ Completado |
| [CU26](<CU26 Gestionar Admision al Programa/README.md>) | Gestionar Admisión al Programa | Media | Web | ✅ Completado |
| [CU27](<CU27 Gestionar Capacitaciones/README.md>) | Gestionar Capacitaciones | Media (propuesta) | Web | ✅ Completado |
| [CU28](<CU28 Registrar Participantes y Asistencia/README.md>) | Registrar Participantes y Asistencia | Media (propuesta) | Web | ✅ Completado |
| [CU29](<CU29 Consultar Capacitaciones/README.md>) | Consultar Capacitaciones | Media (propuesta) | App | ✅ Completado |
| [CU30](<CU30 Gestionar Documentos/README.md>) | Gestionar Documentos | Media (propuesta) | Web y app | 🟡 Parcial (app sin descarga) |
| [CU31](<CU31 Gestionar Base de Conocimiento/README.md>) | Gestionar Base de Conocimiento | Media (propuesta) | Web | ✅ Completado |

**Resumen:** 30 completados y 1 parcial (CU30: falta descargar desde la app). Los 31 casos del plan tienen carpeta.

Fuente del alcance y las fases: `doc/Plan de finalización EmprendeU para el agente.pdf` y
`Backend/EmprendeU/ROADMAP.md`.
