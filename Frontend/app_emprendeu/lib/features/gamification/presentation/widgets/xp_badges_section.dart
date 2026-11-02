import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/gamification_profile.dart';
import '../controllers/gamification_providers.dart';

/// XP acumulado, nivel, insignias obtenidas y últimos movimientos (CU08).
/// Se monta en la pestaña Perfil.
class XpBadgesSection extends ConsumerWidget {
  const XpBadgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final profile = ref.watch(gamificationProfileProvider);
    return profile.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Column(
        children: [
          Text(
            error is Failure ? error.message : 'No se pudo cargar tu progreso.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ref.invalidate(gamificationProfileProvider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
      data: (p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.xp} XP · Nivel ${p.level}', style: text.titleMedium),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (p.progressPct / 100).clamp(0, 1),
                    minHeight: 10,
                    semanticsLabel: 'Avance hacia el siguiente nivel',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.missingXp == null
                      ? 'Alcanzaste el nivel máximo.'
                      : 'Te faltan ${p.missingXp} XP para el nivel ${p.level + 1}.',
                  style: text.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Insignias · ${p.earnedBadges.length} de ${p.badges.length}',
            style: text.titleSmall,
          ),
          const SizedBox(height: 8),
          if (p.badges.isEmpty)
            Text(
              'Todavía no hay insignias en el catálogo.',
              style: text.bodyMedium?.copyWith(color: AppColors.muted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final b in p.badges) _BadgeChip(badge: b)],
            ),
          if (p.history.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Últimos movimientos', style: text.titleSmall),
            const SizedBox(height: 4),
            for (final h in p.history.take(5)) _MovementRow(movement: h),
          ],
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final BadgeProgress badge;

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned;
    return Semantics(
      label:
          '${badge.name}. ${earned ? 'Obtenida' : 'Aún no obtenida'}.'
          '${badge.criterion == null ? '' : ' ${badge.criterion}'}',
      child: Chip(
        avatar: Icon(
          earned ? Icons.emoji_events : Icons.lock_outline,
          size: 18,
          color: earned ? AppColors.successDark : AppColors.muted,
        ),
        label: Text(badge.name),
        backgroundColor: earned ? AppColors.blue50 : null,
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final XpMovement movement;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final date = movement.date;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.reason ?? 'Movimiento de XP'),
                if (date != null)
                  Text(
                    relativeTime(date),
                    style: text.bodySmall?.copyWith(color: AppColors.muted),
                  ),
              ],
            ),
          ),
          Text(
            '${movement.amount >= 0 ? '+' : ''}${movement.amount} XP',
            style: text.labelLarge?.copyWith(color: AppColors.successDark),
          ),
        ],
      ),
    );
  }
}
