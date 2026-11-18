import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/notifications_providers.dart';
import '../notifications_routes.dart';

/// Campana con el número de avisos sin leer; abre la bandeja.
class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final label = unread == 0
        ? 'Notificaciones'
        : 'Notificaciones, $unread sin leer';
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: IconButton(
        tooltip: 'Notificaciones',
        onPressed: () => context.push(NotificationsRoutes.inbox),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          minimumSize: const Size(44, 44),
          side: const BorderSide(color: AppColors.border),
        ),
        icon: Badge(
          isLabelVisible: unread > 0,
          backgroundColor: AppColors.accent,
          label: Text(unread > 9 ? '9+' : '$unread'),
          child: const Icon(Icons.notifications_outlined, color: AppColors.ink),
        ),
      ),
    );
  }
}
