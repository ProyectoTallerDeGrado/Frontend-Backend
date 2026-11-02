import 'dart:io';

/// URL del backend para las pruebas de integración, o `null` si no se definió (la prueba se omite).
///
/// Se define con `--dart-define=API_BASE_URL=...` (emulador Android: `http://10.0.2.2:8000/api/v1`;
/// simulador de iOS o equipo de escritorio: `http://127.0.0.1:8000/api/v1`) o, como antes,
/// con la variable de entorno `API_BASE_URL`.
String? backendUrl() {
  const defined = String.fromEnvironment('API_BASE_URL');
  if (defined.isNotEmpty) return defined;
  final fromEnv = Platform.environment['API_BASE_URL'];
  return (fromEnv == null || fromEnv.isEmpty) ? null : fromEnv;
}

/// Credenciales de un administrador existente (para que la prueba prepare datos del personal).
({String email, String password})? adminCredentials() {
  const email = String.fromEnvironment('E2E_ADMIN_EMAIL');
  const password = String.fromEnvironment('E2E_ADMIN_PASSWORD');
  if (email.isNotEmpty && password.isNotEmpty) {
    return (email: email, password: password);
  }
  final env = Platform.environment;
  final e = env['E2E_ADMIN_EMAIL'];
  final p = env['E2E_ADMIN_PASSWORD'];
  return (e == null || p == null || e.isEmpty || p.isEmpty)
      ? null
      : (email: e, password: p);
}
