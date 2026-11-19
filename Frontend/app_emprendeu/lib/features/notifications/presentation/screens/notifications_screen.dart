import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/app_notification.dart';
import '../controllers/notifications_providers.dart';

/// Bandeja de avisos: mentorías, compromisos, capacitaciones, etapa e insignias.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider);
    final hasUnread = list.value?.hasUnread ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () async {
                final failure = await ref
                    .read(notificationsProvider.notifier)
                    .markAllRead();
                if (failure != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(failure.message)));
                }
              },
              child: const Text('Marcar todo leído'),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(notificationsProvider)
              ..invalidate(unreadCountProvider);
            await ref
                .read(notificationsProvider.future)
                .catchError(
                  (_) => const NotificationsList(items: [], page: 1, total: 0),
                );
          },
          child: list.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ErrorState(
                  message: error is Failure
                      ? error.message
                      : 'No se pudieron cargar tus notificaciones.',
                  onRetry: () => ref.invalidate(notificationsProvider),
                ),
              ],
            ),
            data: (data) => data.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 48),
                      EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'Sin notificaciones',
                        message:
                            'Aquí verás tus mentorías, compromisos, '
                            'capacitaciones y logros.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: data.items.length + (data.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => i == data.items.length
                        ? const _LoadMore()
                        : _NotificationTile(notification: data.items[i]),
                  ),
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(String kind) => switch (kind) {
  'compromiso_nuevo' || 'recordatorio_compromiso' => Icons.task_alt_rounded,
  'recomendacion_nueva' => Icons.lightbulb_outline_rounded,
  'capacitacion_nueva' || 'capacitacion_inscrito' => Icons.school_outlined,
  'etapa_avanzada' => Icons.trending_up_rounded,
  'insignia_ganada' => Icons.workspace_premium_outlined,
  'sesion_cancelada' => Icons.event_busy_outlined,
  _ => Icons.event_outlined,
};

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final n = notification;
    final route = safeRoute(n.route);
    return Semantics(
      button: route != null,
      label: n.read ? null : 'Sin leer',
      child: Material(
        color: n.read ? AppColors.surface : AppColors.blue50,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            ref.read(notificationsProvider.notifier).markRead(n.id);
            if (route != null) context.go(route);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: n.read ? AppColors.border : AppColors.blue100,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: n.read ? AppColors.neutralFill : AppColors.blue100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconFor(n.kind),
                    size: 22,
                    color: n.read ? AppColors.muted : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: text.titleSmall?.copyWith(
                          fontWeight: n.read
                              ? FontWeight.w600
                              : FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(n.body, style: text.bodyMedium),
                      const SizedBox(height: 6),
                      Text(
                        relativeTime(n.createdAt),
                        style: text.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (!n.read)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 6),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadMore extends ConsumerStatefulWidget {
  const _LoadMore();

  @override
  ConsumerState<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends ConsumerState<_LoadMore> {
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    final failure = await ref.read(notificationsProvider.notifier).loadMore();
    if (!mounted) return;
    setState(() => _loading = false);
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Center(
      child: _loading
          ? const CircularProgressIndicator()
          : OutlinedButton(onPressed: _load, child: const Text('Cargar más')),
    ),
  );
}
