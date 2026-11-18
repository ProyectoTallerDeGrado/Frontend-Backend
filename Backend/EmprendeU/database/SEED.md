kit# Datos de demostración (seed)

Script: `src/emprendeu/db/seed.py`. Carga personas y actividad **coherentes con el programa
del CIE-U** para poder probar la web y la app sin tener que capturar nada a mano.

## Cuándo se ejecuta

- **Una sola vez:** solo si la tabla `usuario` está vacía. Si ya hay usuarios, no toca nada
  (se puede lanzar las veces que haga falta). Para volver a sembrar hay que vaciar la base
  (`docker compose down -v`).
- **Nunca en producción:** con `ENVIRONMENT=production` se niega a correr.
- **Docker:** el servicio `seed` de `docker-compose.yml` corre después de `migrate` y antes de la
  API. Se desactiva con `SEED_DEMO_DATA=false` en el `.env`.
- **A mano** (con `alembic upgrade head` ya aplicado):

```bash
uv run python -m emprendeu.db.seed
```

Los catálogos (roles, permisos, etapas, retos, insignias, tipos de sesión y de alerta,
indicadores, parámetros) **no** los crea el seed: ya los siembran las migraciones. El seed solo
añade personas y actividad sobre ellos.

## Cuentas principales para probar

**Contraseña de todas: `Demo12345!`** · dominio `@emprendeu.bo`

| Rol | Correo | Para probar |
|---|---|---|
| Administrador | `admin@emprendeu.bo` | Usuarios, roles y permisos, parámetros, catálogos y auditoría |
| Coordinador | `coordinador@emprendeu.bo` | Todo el panel: emprendimientos, asignaciones, alertas, dashboard, reportes, postulaciones |
| Asesor / mentor | `asesor@emprendeu.bo` | Mentor de Café Altiplano, AgroSensor, EcoEnvases y Delivery Barrio |
| Asesor / mentor | `asesora2@emprendeu.bo` | Mentora de Tejidos Andinos y Clases a Mano |
| Emprendedor | `emprendedor@emprendeu.bo` | **Cuenta principal de la app:** Camino, XP, insignias, mentorías, compromisos |

El resto son datos de relleno: emprendedores `mateo`, `valeria`, `diego`, `camila`, `sebastian`,
`andrea` y `joaquin` (`@emprendeu.bo`, misma contraseña).

## Qué contiene

Seis emprendimientos en distintos momentos, para ver cada estado de la interfaz:

| Emprendimiento | Equipo | Retos | Etapa actual | XP (nivel) | Situación |
|---|---|---|---|---|---|
| Café Altiplano | Lucía (fundadora) + Mateo | 3 de 6 | Preincubación | 425 (3) | Al día; **equipo de 2** y cuenta principal |
| AgroSensor | Valeria | 5 de 6 | Incubación | 775 (4) | Buen ritmo, piloto con agricultores |
| Tejidos Andinos | Diego | 6 de 6 | Crecimiento | 1325 (5) | El más avanzado; ventas en alza |
| Clases a Mano | Camila | 2 de 6 | Preincubación | 225 (2) | Sentimiento del Coach en caída (alerta) |
| EcoEnvases | Sebastián + Andrea | 1 de 6 | Preincubación | 75 (1) | Inactivo 26 días y compromiso vencido (alertas) |
| Delivery Barrio | Joaquín | 0 de 6 | Preincubación | 0 (1) | Nunca registró avances (alerta revisada) |

- **Camino y gamificación:** retos cumplidos en orden con su `MovimientoXp`, y las insignias
  que corresponden (Primer paso, Validador, Conector, Graduado) con su XP. La etapa del
  emprendimiento y su historial salen de los retos cumplidos. Así el CU06 muestra cifras que
  cuadran (por ejemplo Café Altiplano: 270 XP de retos + 155 de insignias = 425, nivel 3).
- **Mentorías:** perfiles de mentor habilitados, una asignación activa por emprendimiento,
  9 sesiones (6 realizadas con recomendaciones y compromisos, 3 programadas que ocupan su
  horario) y bloques de disponibilidad libres dentro de los próximos días.
- **Seguimiento:** avances semanales con porcentaje, hitos cumplidos y pendientes, y
  necesidades detectadas.
- **Alertas:** 4, coherentes con la actividad (inactividad, compromiso vencido, sentimiento).
- **Indicadores:** ventas, clientes y empleos de tres periodos (2026-08 a 2026-10) para Café
  Altiplano, AgroSensor y Tejidos Andinos; los demás quedan sin datos a propósito.
- **Capacitaciones:** 3 (2 realizadas con asistencia, 1 programada).
- **Postulaciones:** 2 pendientes, 1 rechazada y 1 admitida (la de Café Altiplano).
- **Bitácora:** el alta de cada cuenta.

Las fechas son relativas al momento de la siembra (el programa «empezó» hace ~2 meses).

## Lo que NO incluye

- Base de conocimiento ni conversaciones del Coach IA: requieren Ollama y embeddings reales.
  Se suben desde `/knowledge`.
- Documentos y evidencias de hitos (necesitan archivos en disco).
