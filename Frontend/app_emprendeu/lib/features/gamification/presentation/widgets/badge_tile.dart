import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/gamification_profile.dart';

/// Insignia del catálogo (obtenida o bloqueada). Al tocarla abre su detalle.
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge});

  final BadgeProgress badge;

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned;
    return Semantics(
      button: true,
      label:
          '${badge.name}. ${earned ? 'Obtenida' : 'Aún no obtenida'}.'
          '${badge.criterion == null ? '' : ' ${badge.criterion}'}',
      excludeSemantics: true,
      child: ActionChip(
        avatar: Icon(
          earned ? Icons.emoji_events : Icons.lock_outline,
          size: 18,
          color: earned ? AppColors.successDark : AppColors.muted,
        ),
        label: Text(badge.name),
        backgroundColor: earned ? AppColors.blue50 : null,
        onPressed: () => showBadgeSheet(context, badge),
      ),
    );
  }
}

/// Hoja inferior con el detalle de una insignia: criterio, XP y fecha.
Future<void> showBadgeSheet(BuildContext context, BadgeProgress badge) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.navy950.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _BadgeSheet(badge: badge),
  );
}

class _BadgeSheet extends StatelessWidget {
  const _BadgeSheet({required this.badge});

  final BadgeProgress badge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final earnedAt = badge.earnedAt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                badge.earned ? Icons.emoji_events : Icons.lock_outline,
                color: badge.earned ? AppColors.successDark : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(badge.name, style: text.titleLarge)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            badge.criterion ?? 'Esta insignia no tiene un criterio descrito.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text('Recompensa: +${badge.xpReward} XP', style: text.labelLarge),
          const SizedBox(height: 4),
          Text(
            badge.earned
                ? (earnedAt == null
                      ? 'Obtenida'
                      : 'Obtenida · ${longDate(earnedAt.toLocal())}')
                : 'Aún no la obtienes.',
            style: text.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
