import '../../../../core/error/result.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repository);
  final NotificationsRepository _repository;

  Future<Result<NotificationsPage>> call({int page = 1}) =>
      _repository.getNotifications(page: page);
}

class GetUnreadCountUseCase {
  const GetUnreadCountUseCase(this._repository);
  final NotificationsRepository _repository;

  Future<Result<int>> call() => _repository.unreadCount();
}

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);
  final NotificationsRepository _repository;

  Future<Result<AppNotification>> call(int id) => _repository.markRead(id);
}

class MarkAllNotificationsReadUseCase {
  const MarkAllNotificationsReadUseCase(this._repository);
  final NotificationsRepository _repository;

  Future<Result<void>> call() => _repository.markAllRead();
}

class RegisterPushDeviceUseCase {
  const RegisterPushDeviceUseCase(this._repository);
  final NotificationsRepository _repository;

  Future<Result<void>> call(String token, String platform) =>
      _repository.registerDevice(token, platform);
}
