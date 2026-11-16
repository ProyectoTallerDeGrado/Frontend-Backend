import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../controllers/gamification_providers.dart';
import '../widgets/badge_tile.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_level_card.dart';
import '../widgets/xp_movement_row.dart';
import '../../../../shared/widgets/state_views.dart';

/// «Experiencia e insignias» (CU08): XP acumulado, nivel, insignias y movimientos.
class XpBadgesScreen extends ConsumerWidget {
  const XpBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final profile = ref.watch(gamificationProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Experiencia e insignias')),
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorState(
                message: error is Failure
                    ? error.message
                    : 'No se pudo cargar tu progreso.',
                onRetry: () => ref.invalidate(gamificationProfileProvider),
              ),
            ),
          ),
          data: (p) => RefreshIndicator(
            onRefresh: () => ref.refresh(gamificationProfileProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                XpLevelCard(profile: p),
                if (p.xp == 0 && p.earnedBadges.isEmpty) ...[
                  const SizedBox(height: 14),
                  const XpEmptyState(),
                ],
                const SizedBox(height: 18),
                Text(
                  'Insignias · ${p.earnedBadges.length} de ${p.badges.length}',
                  style: text.titleSmall,
                ),
                const SizedBox(height: 8),
                if (p.badges.isEmpty)
                  const Text('Todavía no hay insignias en el catálogo.')
                else
                  BadgeGrid(badges: p.badges),
                const SizedBox(height: 18),
                Text('Movimientos de XP', style: text.titleSmall),
                const SizedBox(height: 4),
                if (p.history.isEmpty)
                  const Text('Todavía no tienes movimientos de XP.')
                else
                  for (final h in p.history) XpMovementRow(movement: h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
