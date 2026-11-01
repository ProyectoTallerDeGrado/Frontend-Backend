/// Configuración de la app. Se fija al compilar con `--dart-define`:
///
///     flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
///
/// El valor por defecto apunta al backend de la máquina anfitriona desde el
/// emulador de Android (`10.0.2.2`). En el simulador de iOS usa `127.0.0.1`.
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.137:8000/api/v1',
  );
}
