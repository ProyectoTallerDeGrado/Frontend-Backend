import '../../../../core/error/result.dart';
import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<Result<NotificationsPage>> getNotifications({int page = 1});

  Future<Result<int>> unreadCount();

  Future<Result<AppNotification>> markRead(int id);

  Future<Result<void>> markAllRead();

  /// Registra el token FCM del celular para la cuenta con sesión abierta.
  Future<Result<void>> registerDevice(String token, String platform);
}
