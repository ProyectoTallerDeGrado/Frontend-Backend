import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/widgets/motion.dart';
import '../../../auth/index.dart';
import '../../../gamification/index.dart';
import '../../../mentoring/index.dart';
import '../../../notifications/index.dart';
import '../../../ventures/index.dart';
import '../widgets/next_challenge_card.dart';
import '../widgets/progress_card.dart';
import '../../../../shared/widgets/state_views.dart';

/// Inicio del emprendedor: composición de las features `ventures`, `gamification` y `mentoring`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(myVenturesProvider)
      ..invalidate(gamificationProfileProvider)
      ..invalidate(journeyProvider)
      ..invalidate(commitmentsProvider)
      ..invalidate(progressLogsProvider)
      ..invalidate(unreadCountProvider);
    await ref.read(syncControllerProvider.notifier).sync();
    await ref.read(myVentureProvider.future).catchError((_) => null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final user = ref.watch(authControllerProvider).value?.user;
    final venture = ref.watch(myVentureProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          longDate(DateTime.now()),
                          style: text.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Semantics(
                          header: true,
                          child: Text(
                            'Hola, ${user?.nombre ?? ''}',
                            style: text.headlineMedium,
                          ),
                        ),
                        if (venture.value != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              venture.value!.name,
                              style: text.bodyMedium?.copyWith(
                                fontSize: 14,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const ConnectionPill(),
                  const SizedBox(width: 8),
                  const NotificationsBell(),
                ],
              ),
              const SizedBox(height: 18),
              const SyncBanner(),
              const VentureSwitcher(),
              ...venture.when(
                data: (v) => v == null
                    ? [const SizedBox(height: 4), const CreateVentureCard()]
                    : _content(context, ref, v),
                loading: () => [
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, _) => [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ErrorState(
                      message: e is Failure
                          ? e.message
                          : 'No se pudo cargar tu información.',
                      onRetry: () => ref.invalidate(myVenturesProvider),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref, Venture venture) {
    final profile = ref.watch(gamificationProfileProvider);
    final journey = ref.watch(journeyProvider);
    return [
      const SizedBox(height: 18),
      profile.when(
        data: (p) => ProgressCard(profile: p, stageName: venture.stageName),
        loading: () => Semantics(
          label: 'Cargando tu progreso',
          child: const Skeleton(height: 144, radius: 24),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
      const SizedBox(height: 18),
      journey.maybeWhen(
        data: (j) => NextChallengeCard(
          journey: j,
          onOpenJourney: () => context.go(GamificationRoutes.journey),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
      const SizedBox(height: 22),
      const CommitmentsSection(),
      const SizedBox(height: 22),
      const ProgressSection(),
    ];
  }
}
