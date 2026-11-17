import 'dart:async';

import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/notifications/domain/entities/app_notification.dart';
import 'package:app_emprendeu/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:app_emprendeu/features/notifications/domain/repositories/push_messaging.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({List<AppNotification>? items})
    : items = items ?? [];

  List<AppNotification> items;
  final registered = <(String, String)>[];
  int markAllCalls = 0;

  @override
  Future<Result<NotificationsPage>> getNotifications({int page = 1}) async =>
      Result.ok(
        NotificationsPage(
          items: items
              .skip((page - 1) * notificationsPageSize)
              .take(notificationsPageSize)
              .toList(),
          page: page,
          total: items.length,
        ),
      );

  @override
  Future<Result<int>> unreadCount() async =>
      Result.ok(items.where((n) => !n.read).length);

  @override
  Future<Result<AppNotification>> markRead(int id) async {
    items = [for (final n in items) n.id == id ? n.markRead() : n];
    return Result.ok(items.firstWhere((n) => n.id == id));
  }

  @override
  Future<Result<void>> markAllRead() async {
    markAllCalls++;
    items = [for (final n in items) n.markRead()];
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> registerDevice(String token, String platform) async {
    registered.add((token, platform));
    return const Result.ok(null);
  }
}

/// Push simulado: `enabled` = Firebase configurado y permiso concedido.
class FakePushMessaging implements PushMessaging {
  FakePushMessaging({this.enabled = true, this.initial});

  final bool enabled;
  final PushNotice? initial;
  String currentToken = 'fcm-1';
  int deleteCalls = 0;
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushNotice>.broadcast();
  final opened = StreamController<PushNotice>.broadcast();

  @override
  Future<bool> start() async => enabled;

  @override
  String get platform => 'android';

  @override
  Future<String?> token() async => enabled ? currentToken : null;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<PushNotice> get onForeground => foreground.stream;

  @override
  Stream<PushNotice> get onOpened => opened.stream;

  @override
  Future<PushNotice?> initialNotice() async => initial;

  @override
  Future<void> deleteToken() async => deleteCalls++;
}

AppNotification notice(
  int id, {
  String title = 'Aviso',
  String body = 'Cuerpo',
  String? route,
  bool read = false,
  String kind = 'sesion_cancelada',
}) => AppNotification(
  id: id,
  kind: kind,
  title: title,
  body: body,
  route: route,
  read: read,
  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
);
