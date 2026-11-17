import 'package:dio/dio.dart';

import '../models/notification_dto.dart';

/// Llamadas HTTP de `/notifications`. Lanza [DioException]; el repositorio las mapea.
class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({List<NotificationDto> items, int total})> list({
    required int page,
    required int pageSize,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final data = response.data!;
    return (
      items: (data['items'] as List<dynamic>)
          .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int,
    );
  }

  Future<int> unreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications/unread-count',
    );
    return response.data!['no_leidas'] as int;
  }

  Future<NotificationDto> markRead(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/notifications/$id/read',
    );
    return NotificationDto.fromJson(response.data!);
  }

  Future<void> markAllRead() => _dio.post<void>('/notifications/read-all');

  Future<void> registerDevice(String token, String platform) => _dio.put<void>(
    '/notifications/devices',
    data: {'token': token, 'plataforma': platform},
  );
}
