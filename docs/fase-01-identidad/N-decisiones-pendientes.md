# N — Decisiones pendientes

Tipo: **Inst.** = la decide el CIE-U (regla institucional). **Téc.** = la decide el
equipo técnico o el responsable del repositorio.

Cada decisión trae un **valor por defecto seguro** con el que se puede implementar
sin bloquear. Cambiarlo después no requiere tocar código, salvo donde se indica.

| # | Tipo | Pregunta | Valor por defecto del diseño | Cómo se aplica el cambio |
|---|---|---|---|---|
| N-01 | Inst. | ¿Pueden los emprendedores registrarse solos (p. ej., con el correo institucional)? | **No.** Solo alta controlada con invitación. | Nueva fase: el endpoint crea cuentas `pendiente` + `EMPRENDEDOR` con la aprobación de un coordinador. |
| N-02 | Inst. | ¿Es obligatorio un dominio de correo institucional? ¿Para qué roles? | Se acepta cualquier dominio. | Configuración `ALLOWED_EMAIL_DOMAINS` por rol (una validación pequeña en `users`). |
| N-03 | Inst. | ¿Habrá SSO institucional (Google Workspace, Microsoft Entra, CAS)? | No. Solo contraseña local. | Nueva fase; redefine el significado de `password_hash` NULL (B §5.3). |
| N-04 | Inst. | **Alcance del coordinador:** ¿institucional o por asignación? ¿El administrador debe ver información empresarial? ¿Quién mantiene la base de conocimiento de la IA? | Coordinador **institucional**. Administrador **sin** acceso a negocio. Conocimiento de la IA: coordinador. | Una migración de `rol_permiso` (C-D §5–§6). |
| N-05 | Inst. | ¿Puede el coordinador dar de alta mentores? | No. Solo el administrador. | Una migración que concede `roles.assign.mentor` a `COORDINADOR`. |
| N-06 | Inst. | ¿Puede haber mentores externos (sin correo institucional)? ¿Con qué requisitos? | Se permite (no se valida el dominio). | Depende de N-02. |
| N-07 | Inst. | ¿`documento_identidad` debe ser único? ¿Qué tipos de documento se aceptan? | No es único (como en la base actual). | Una migración del módulo `entrepreneurs`. |
| N-08 | Inst. | ¿Hay una política de contraseñas institucional? | NIST: 12 caracteres mínimo, sin composición obligatoria, lista de bloqueo, sin caducidad. | Variables de entorno y la lista de bloqueo. |
| N-09 | Inst. | ¿Puede un mentor estar asignado a un emprendimiento del que es miembro? | **No** (`409 conflict_of_interest` en la fase de `mentoring`). | Una regla del servicio de asignaciones. |
| N-10 | Inst. + Téc. | ¿Qué servidor de correo se usa (SMTP institucional, proveedor)? Si no hay correo, ¿puede el administrador entregar a mano un enlace de activación? | SMTP configurable. **El enlace nunca se muestra al administrador.** | Si se aprueba la entrega manual: un endpoint que devuelve el enlace una sola vez, con auditoría reforzada (el administrador podría fijar la contraseña ajena). **No recomendado.** |
| N-11 | Inst. | Duraciones: la sesión web y la móvil (inactividad y absoluta), la invitación y el restablecimiento. | Web 7 d / 30 d; móvil 30 d / 90 d; invitación 72 h; restablecimiento 30 min; access 15 min. | Variables de entorno. |
| N-12 | Inst. | ¿Cuánto se conserva la `bitacora`? ¿Qué ley de protección de datos aplica? ¿Hay un procedimiento de anonimización o derecho al olvido? | Se conserva indefinidamente; sin borrado. | Una fase propia (anonimización de `usuario` conservando las FK). |
| N-13 | Inst. | **Capacidades de escritura del emprendedor y del mentor:** crear o editar el propio emprendimiento, registrar hitos e indicadores propios, marcar compromisos, avanzar etapas (el mentor), asignar retos (el mentor), inscribirse en capacitaciones. | Todas **no concedidas** (`○` en C §3). | Una migración de `rol_permiso` por cada una que se apruebe. |
| N-14 | Inst. + Téc. | ¿Se necesita editar la matriz de permisos desde la UI? | **No.** Solo con una migración revisada. | Una fase propia con controles adicionales (doble aprobación). |
| N-15 | Téc. | ¿Otro servicio (BFF, microservicio) necesitará verificar los JWT por su cuenta? | No → HS256. | Pasar a EdDSA, añadiendo `cryptography` y publicando un JWKS. |
| N-16 | Téc. | ¿Usar `forbidden()` de Next 16, que es experimental (`authInterrupts`)? | Sí, con *fallback* documentado (J §5). | El *flag* en `next.config.ts`. |
| N-17 | Téc. + Inst. | ¿Se añade `emprendimiento_emprendedores.fecha_salida`? ¿La creación del perfil emprendedor (`POST /entrepreneurs`) entra en la fase de identidad o en la de `entrepreneurs`? | Se propone añadir `fecha_salida`; el perfil, en la fase de `entrepreneurs`. | Migración #4 (E-H §1.3). |
| N-18 | Inst. | ¿Ve el emprendedor las `observaciones` que escribe el mentor en las sesiones de acompañamiento? | No (se excluyen de la respuesta al alcance `own`). | Una regla de serialización en `mentoring`. |
| N-19 | Inst. | Límites del XP manual (máximo por movimiento, motivos permitidos). | `cantidad` entre −500 y 500, con un motivo obligatorio. | La configuración de `gamification`. |
| N-20 | Inst. | ¿Ve el emprendedor las alertas de su emprendimiento? | No. | Una migración de `rol_permiso`. |
| N-21 | Inst. | ¿Pueden mentores o coordinadores leer las conversaciones con la IA y el análisis de sentimiento de un emprendedor? | **No** (es un dato muy sensible). | Una migración de `rol_permiso` + el aviso de privacidad al emprendedor. |
| N-22 | Inst. | El vocabulario de `asignaciones.tipo_asignacion` (`mentoria`, `coordinacion`...) y quién asigna a los coordinadores si su alcance es por asignación. | `mentoria` y `coordinacion`. Solo un coordinador asigna. | Un CHECK en la fase de `mentoring`. |
| N-23 | Inst. | La zona horaria institucional para interpretar "hasta el día D". | UTC (sin conversión) hasta que se defina: el repositorio no indica ninguna zona. | La configuración `INSTITUTION_TIMEZONE`. |
| N-24 | Inst. | El vocabulario de `emprendimiento.estado` y qué estados bloquean la escritura. | `activo`, `pausado`, `cerrado`, `archivado`; se bloquea la escritura en `cerrado` y `archivado`. | La fase de `ventures`. |
| N-25 | Téc. | ¿Dónde se ejecuta la purga periódica (cron del sistema, un *scheduler* del despliegue)? | El cron del sistema, a diario. | Operación. |
| N-26 | Téc. | ¿*Certificate pinning* en el móvil? | No. | La configuración de Dio. |
| N-27 | Inst. | ¿Puede el usuario editar su nombre o su correo? | Solo el teléfono. | `PATCH /auth/me` (y, para el correo, un flujo de verificación). |
| N-28 | Téc. | ¿Se aceptan `repository.py` y `service.py` mínimos en `mentoring` y `entrepreneurs`, solo con el resolvedor de alcance? (K §1.6) | **Sí** (recomendado). | Si no: los flujos I-17…I-20 se posponen. |
| N-29 | Téc. | **a)** ¿Hay un PostgreSQL para tests en local y en CI? **b)** ¿Se aprueba un *runner* de tests web (Playwright para E2E, Vitest para unidades)? | a) No verificado: hay que comprobarlo antes de implementar. b) Pendiente: la web no tiene *runner* hoy [C]. | Infraestructura y `devDependencies`. |
| N-30 | Téc. | El trabajo sin commitear del worktree `auth-module` (cookies y CSRF en el backend, un `jwt_secret_key` sin `kid`), ¿se descarta, se adapta o sustituye a este diseño? | Adaptarlo a este diseño (DA-01, DA-04). | Una decisión antes de la primera fase de implementación. |
| N-31 | Téc. | La topología de despliegue: los dominios de la web y de la API, el proxy inverso y sus IP (`TRUSTED_PROXIES`), y si la API es pública (sí, para el móvil). | API pública con HTTPS; la web en su propio dominio; `TRUSTED_PROXIES` vacío hasta que se defina (R-03). | Variables de entorno. |
