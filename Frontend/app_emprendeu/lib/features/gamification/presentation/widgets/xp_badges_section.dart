import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../controllers/gamification_providers.dart';
import '../gamification_routes.dart';
import 'xp_empty_state.dart';
import 'xp_level_card.dart';
import '../../../../shared/widgets/state_views.dart';

/// Resumen de XP, nivel e insignias en la pestaña Perfil (CU08). El detalle
/// completo está en la pantalla «Experiencia e insignias» (`/xp`).
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
      error: (error, _) => ErrorState(
        message: error is Failure
            ? error.message
            : 'No se pudo cargar tu progreso.',
        onRetry: () => ref.invalidate(gamificationProfileProvider),
      ),
      data: (p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.xp == 0 && p.earnedBadges.isEmpty)
            const XpEmptyState()
          else
            XpLevelCard(profile: p),
          const SizedBox(height: 10),
          Text(
            'Insignias · ${p.earnedBadges.length} de ${p.badges.length}',
            style: text.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(GamificationRoutes.xp),
            icon: const Icon(Icons.emoji_events_outlined, size: 18),
            label: const Text('Ver experiencia e insignias'),
          ),
        ],
      ),
    );
  }
}
