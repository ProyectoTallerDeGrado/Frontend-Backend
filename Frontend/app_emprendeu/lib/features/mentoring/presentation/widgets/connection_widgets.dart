import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/connectivity/online_controller.dart';
import '../controllers/mentoring_providers.dart';

/// Píldora «En línea» / «Sin conexión» del encabezado del Inicio.
class ConnectionPill extends ConsumerWidget {
  const ConnectionPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider);
    final (bg, fg, dot, label) = online
        ? (
            AppColors.successTint,
            AppColors.successDark,
            AppColors.success,
            'En línea',
          )
        : (
            AppColors.warningTint,
            AppColors.warningOn,
            AppColors.warning,
            'Sin conexión',
          );
    return Semantics(
      label: online ? 'En línea' : 'Sin conexión',
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso bajo el encabezado: sin conexión (con pendientes), sincronizando o todo sincronizado.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider);
    final sync = ref.watch(syncControllerProvider);

    final String message;
    final Color bg, fg;
    final Widget leading;
    if (sync.phase == SyncPhase.syncing) {
      message =
          'Sincronizando ${sync.pending} ${sync.pending == 1 ? 'registro' : 'registros'}…';
      bg = AppColors.blue50;
      fg = AppColors.blue800;
      leading = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.blue800,
        ),
      );
    } else if (sync.phase == SyncPhase.done) {
      message = 'Todo sincronizado.';
      bg = AppColors.successTint;
      fg = AppColors.successDark;
      leading = const Icon(Icons.check, size: 20, color: AppColors.successDark);
    } else if (!online) {
      message =
          'Sin conexión. Tus registros se guardan en este dispositivo y se sincronizarán después.'
          '${sync.pending > 0 ? ' Pendientes: ${sync.pending}.' : ''}';
      bg = AppColors.warningTint;
      fg = AppColors.warningOn;
      leading = const Icon(
        Icons.cloud_off_outlined,
        size: 20,
        color: AppColors.warningOn,
      );
    } else {
      return const SizedBox.shrink();
    }

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
