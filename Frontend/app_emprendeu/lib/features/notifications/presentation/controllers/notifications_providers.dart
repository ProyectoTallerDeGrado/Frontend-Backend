import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/repositories/push_messaging.dart';
import '../../domain/usecases/notifications_usecases.dart';

/// Contratos; las implementaciones se inyectan en `app/providers.dart`.
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => throw UnimplementedError(
    'notificationsRepositoryProvider sin implementación',
  ),
);
/// Por defecto sin push; `data` lo reemplaza por Firebase en la app real.
final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => const DisabledPushMessaging(),
);

final getNotificationsUseCaseProvider = Provider(
  (ref) => GetNotificationsUseCase(ref.watch(notificationsRepositoryProvider)),
);
final getUnreadCountUseCaseProvider = Provider(
  (ref) => GetUnreadCountUseCase(ref.watch(notificationsRepositoryProvider)),
);
final markNotificationReadUseCaseProvider = Provider(
  (ref) =>
      MarkNotificationReadUseCase(ref.watch(notificationsRepositoryProvider)),
);
final markAllNotificationsReadUseCaseProvider = Provider(
  (ref) => MarkAllNotificationsReadUseCase(
    ref.watch(notificationsRepositoryProvider),
  ),
);
final registerPushDeviceUseCaseProvider = Provider(
  (ref) =>
      RegisterPushDeviceUseCase(ref.watch(notificationsRepositoryProvider)),
);

/// Avisos sin leer (la campana de Inicio). Si falla la red se muestra 0.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final result = await ref.watch(getUnreadCountUseCaseProvider)();
  return result.valueOrNull ?? 0;
});

/// Lo que muestra la bandeja: lo cargado hasta ahora y si faltan páginas.
class NotificationsList {
  const NotificationsList({
    required this.items,
    required this.page,
    required this.total,
  });

  final List<AppNotification> items;
  final int page;
  final int total;

  bool get hasMore => page * notificationsPageSize < total;
  bool get hasUnread => items.any((n) => !n.read);

  NotificationsList copyWith({List<AppNotification>? items, int? page}) =>
      NotificationsList(
        items: items ?? this.items,
        page: page ?? this.page,
        total: total,
      );
}

/// Bandeja de avisos, paginada («Cargar más»), con marcar como leído.
class NotificationsController extends AsyncNotifier<NotificationsList> {
  @override
  Future<NotificationsList> build() async {
    final first = (await ref.watch(
      getNotificationsUseCaseProvider,
    )()).getOrThrow();
    return NotificationsList(items: first.items, page: 1, total: first.total);
  }

  Future<Failure?> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return null;
    final result = await ref.read(getNotificationsUseCaseProvider)(
      page: current.page + 1,
    );
    switch (result) {
      case Ok(:final value):
        state = AsyncData(
          current.copyWith(
            items: [...current.items, ...value.items],
            page: value.page,
          ),
        );
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  /// Marca un aviso como leído (se muestra leído aunque falle la red).
  Future<void> markRead(int id) async {
    final current = state.value;
    if (current == null) return;
    final target = current.items.where((n) => n.id == id).firstOrNull;
    if (target == null || target.read) return;
    state = AsyncData(
      current.copyWith(
        items: [for (final n in current.items) n.id == id ? n.markRead() : n],
      ),
    );
    await ref.read(markNotificationReadUseCaseProvider)(id);
    ref.invalidate(unreadCountProvider);
  }

  Future<Failure?> markAllRead() async {
    final result = await ref.read(markAllNotificationsReadUseCaseProvider)();
    if (result.failureOrNull case final failure?) return failure;
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(items: [for (final n in current.items) n.markRead()]),
      );
    }
    ref.invalidate(unreadCountProvider);
    return null;
  }
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationsController,
      NotificationsList
    >(NotificationsController.new);
