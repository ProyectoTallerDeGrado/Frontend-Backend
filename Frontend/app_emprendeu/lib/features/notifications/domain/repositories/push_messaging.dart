import '../entities/app_notification.dart';

/// Mensajería push del sistema (Firebase Cloud Messaging detrás de `data`).
abstract interface class PushMessaging {
  /// Prepara Firebase y pide permiso para mostrar notificaciones.
  /// `false` si no está configurado (falta `google-services.json`) o el usuario
  /// no dio permiso: la app sigue funcionando con la bandeja.
  Future<bool> start();

  /// `android` o `ios`.
  String get platform;

  Future<String?> token();

  Stream<String> get onTokenRefresh;

  /// Push que llega con la app abierta (el sistema no lo muestra solo).
  Stream<PushNotice> get onForeground;

  /// El usuario tocó un push con la app en segundo plano.
  Stream<PushNotice> get onOpened;

  /// El push que abrió la app desde cerrada, si lo hubo.
  Future<PushNotice?> initialNotice();

  /// Invalida el token del celular (al cerrar sesión): FCM deja de entregarle y el
  /// backend borra el dispositivo en el siguiente envío.
  Future<void> deleteToken();
}

/// Sin push (pruebas, escritorio): todo es un no-op y la app usa solo la bandeja.
class DisabledPushMessaging implements PushMessaging {
  const DisabledPushMessaging();

  @override
  Future<bool> start() async => false;

  @override
  String get platform => 'android';

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushNotice> get onForeground => const Stream.empty();

  @override
  Stream<PushNotice> get onOpened => const Stream.empty();

  @override
  Future<PushNotice?> initialNotice() async => null;

  @override
  Future<void> deleteToken() async {}
}
