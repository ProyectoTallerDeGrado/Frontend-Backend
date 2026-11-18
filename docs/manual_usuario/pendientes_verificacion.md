# Pendientes de verificación

## Capturas pendientes
- [CAPTURA PENDIENTE: registro en la app móvil]
- [CAPTURA PENDIENTE: recuperación de contraseña en la app móvil (solicitud y restablecimiento)]
- [CAPTURA PENDIENTE: hojas laterales del panel web: nuevo usuario, nuevo emprendimiento, nuevo emprendedor, registrar sesión, nueva capacitación, subir documento]
- [CAPTURA PENDIENTE: decisión de admisión (admitir/rechazar) y «Contraseña temporal»]
- [CAPTURA PENDIENTE: Coach IA con respuesta y fuentes; descarga de la IA local; «Mis archivos para la IA»]
- [CAPTURA PENDIENTE: cumplir un reto y celebración; registrar avance; reportar necesidad; hitos y evidencia]
- [CAPTURA PENDIENTE: panel web en vista móvil (menú como hoja lateral)]

## Funcionalidades sin comprobar en ejecución
- Envío de correos (recuperación de contraseña): requiere SMTP.
- Notificaciones push (FCM): no existe `android/app/google-services.json`.
- Respuesta del asistente de ayuda con Gemini y del coach (Ollama): el servicio de IA aparecía como «No responde».
- Descarga real de CSV/Excel y subida de documentos: no ejecutadas.
- Escrituras de formularios (crear/editar/eliminar): no se ejecutaron para no modificar datos; los pasos provienen del código.
- iOS: no probado.

## Discrepancias detectadas (no corregidas, fuera del alcance)
- `AGENTS.md` móvil cita `10.0.2.2`; la URL por defecto es `http://192.168.0.137:8000/api/v1`.
- `Frontend/app_emprendeu/design.md` está desactualizado (orden de pestañas, estado de `main.dart`).
- El asesor, con permisos iniciales, entra a `/panel` y ve «Sin acceso a el resumen» (redacción «a el»).
- «Admisiones» exige `emprendedores:registro` en el menú; la pantalla solo comprueba consulta.
- El subtítulo de `/reports` menciona solo CSV, aunque existe «Exportar Excel».
- La compilación Android requirió `--android-skip-build-dependency-validation` (AGP 9.1.0 < 9.1.1 exigido por Flutter 3.50).

## Datos de la demostración
Las capturas usan datos demo (`@emprendeu.bo`). En `web_admin_users.png` se difuminaron dos cuentas ajenas a la demo presentes en la base local.

## Información institucional por confirmar
Autor o equipo responsable, versión oficial y nombre formal de la institución (la web solo menciona «UAGRM»).
