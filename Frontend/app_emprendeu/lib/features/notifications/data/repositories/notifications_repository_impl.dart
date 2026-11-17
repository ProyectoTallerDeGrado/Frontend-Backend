import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e) {
      return Result.err(mapDioException(e));
    } on TypeError {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    }
  }

  @override
  Future<Result<NotificationsPage>> getNotifications({int page = 1}) =>
      _guard(() async {
        final data = await _remote.list(
          page: page,
          pageSize: notificationsPageSize,
        );
        return NotificationsPage(
          items: [for (final n in data.items) n.toEntity()],
          page: page,
          total: data.total,
        );
      });

  @override
  Future<Result<int>> unreadCount() => _guard(_remote.unreadCount);

  @override
  Future<Result<AppNotification>> markRead(int id) =>
      _guard(() async => (await _remote.markRead(id)).toEntity());

  @override
  Future<Result<void>> markAllRead() => _guard(_remote.markAllRead);

  @override
  Future<Result<void>> registerDevice(String token, String platform) =>
      _guard(() => _remote.registerDevice(token, platform));
}
