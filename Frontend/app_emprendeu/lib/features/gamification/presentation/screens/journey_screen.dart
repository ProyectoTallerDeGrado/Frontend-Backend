import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../auth/index.dart';
import '../../../ventures/index.dart';
import '../../domain/entities/completion_result.dart';
import '../../domain/entities/journey.dart';
import '../controllers/gamification_providers.dart';
import '../widgets/celebration_dialog.dart';
import '../widgets/challenge_sheet.dart';
import '../widgets/journey_path.dart';
import '../../../../shared/widgets/state_views.dart';

/// Camino gamificado (pestaña «Camino»).
class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  String? _bubble;
  Timer? _bubbleTimer;

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  Future<void> _open(JourneyChallenge challenge) async {
    final result = await showChallengeSheet(context, challenge);
    if (result == null || !mounted) return;
    _afterCompletion(result);
  }

  void _afterCompletion(CompletionResult result) {
    ref.invalidate(journeyProvider);
    ref.invalidate(gamificationProfileProvider);
    setState(() {
      _bubble = '+${result.xpAwarded} XP';
    });
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _bubble = null);
    });
    if (result.newBadges.isNotEmpty || result.leveledUp) {
      showCelebration(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(journeyProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            journey.when(
              data: (j) => RefreshIndicator(
                onRefresh: () async => ref.refresh(journeyProvider.future),
                child: _JourneyBody(journey: j, onOpen: _open),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _JourneyError(
                failure: error is Failure ? error : const UnknownFailure(),
                onRetry: () => ref.invalidate(journeyProvider),
              ),
            ),
            if (_bubble != null)
              Positioned(
                top: 150,
                left: 0,
                right: 0,
                child: Center(child: _XpBubble(_bubble!)),
              ),
          ],
        ),
      ),
    );
  }
}

class _JourneyBody extends StatelessWidget {
  const _JourneyBody({required this.journey, required this.onOpen});

  final Journey journey;
  final ValueChanged<JourneyChallenge> onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TourTarget(
                id: 'journey-header',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text('Mi camino', style: text.headlineMedium),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy900,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt,
                            size: 16,
                            color: AppColors.accentSoft,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${journey.xp} XP',
                            style: text.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: journey.stages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _StageChip(journey.stages[i]),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: const [
                  _Legend(
                    color: AppColors.success,
                    icon: Icons.check,
                    label: 'Camino verde: cumplido',
                  ),
                  _Legend(
                    color: AppColors.primary,
                    label: 'Camino azul: en curso',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (journey.challenges.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Aún no hay retos disponibles.')),
          )
        else
          JourneyPath(challenges: journey.challenges, onOpen: onOpen),
      ],
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip(this.stage);

  final JourneyStage stage;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, icon) = switch (stage.status) {
      StageStatus.done => (
        AppColors.success,
        Colors.white,
        AppColors.success,
        Icons.check,
      ),
      StageStatus.current => (
        AppColors.primary,
        Colors.white,
        AppColors.primary,
        Icons.remove,
      ),
      StageStatus.locked => (
        Colors.white,
        AppColors.muted,
        AppColors.borderStrong,
        Icons.lock_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 8),
          Text(
            stage.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.icon});

  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: icon == null ? null : Icon(icon, size: 9, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _XpBubble extends StatelessWidget {
  const _XpBubble(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 2000),
        builder: (context, t, child) {
          final opacity = t < 0.2 ? t / 0.2 : (t > 0.8 ? (1 - t) / 0.2 : 1.0);
          return Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, 24 - 70 * t),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _JourneyError extends StatelessWidget {
  const _JourneyError({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (failure is NoVentureFailure) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [CreateVentureCard(onCreated: onRetry)],
      );
    }
    return Center(
      child: ErrorState(
        message: failure.message,
        onRetry: onRetry,
        padding: const EdgeInsets.all(32),
      ),
    );
  }
}
