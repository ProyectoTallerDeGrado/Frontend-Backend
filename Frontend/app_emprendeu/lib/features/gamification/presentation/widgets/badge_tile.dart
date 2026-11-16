import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/gamification_profile.dart';

/// Insignia del catálogo (obtenida o bloqueada) como medalla. Al tocarla abre su detalle.
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge});

  final BadgeProgress badge;

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label:
          '${badge.name}. ${earned ? 'Obtenida' : 'Aún no obtenida'}.'
          '${badge.criterion == null ? '' : ' ${badge.criterion}'}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showBadgeSheet(context, badge),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Medal(earned: earned, size: 56),
                const SizedBox(height: 10),
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: earned ? AppColors.ink : AppColors.muted,
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

/// Rejilla de insignias en tres columnas (`design.md` §9).
class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.badges});

  final List<BadgeProgress> badges;

  @override
  Widget build(BuildContext context) {
    const gap = AppSpacing.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final b in badges)
              SizedBox(
                width: width,
                child: BadgeTile(badge: b),
              ),
          ],
        );
      },
    );
  }
}

/// Medalla: roja con la cinta cuando se ganó, apagada con candado mientras no.
class _Medal extends StatelessWidget {
  const _Medal({required this.earned, required this.size});

  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned ? AppColors.accent : AppColors.neutralFill,
        border: earned
            ? Border.all(color: AppColors.accentTint, width: 3)
            : null,
      ),
      child: Icon(
        earned ? Icons.workspace_premium_rounded : Icons.lock_outline,
        size: size * 0.5,
        color: earned ? AppColors.onNavy : AppColors.muted,
      ),
    );
  }
}

/// Hoja inferior con el detalle de una insignia: criterio, XP y fecha.
Future<void> showBadgeSheet(BuildContext context, BadgeProgress badge) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
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
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Medal(earned: badge.earned, size: 48),
              const SizedBox(width: 14),
              Expanded(child: Text(badge.name, style: text.titleLarge)),
            ],
          ),
          const SizedBox(height: 16),
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
