import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../shared/widgets/motion.dart';
import '../../domain/entities/completion_result.dart';

/// Celebra subir de nivel o ganar una insignia: es el momento que la app más quiere que se
/// note, así que ocupa la pantalla en vez de pasar como un aviso al pie.
Future<void> showCelebration(BuildContext context, CompletionResult result) {
  HapticFeedback.mediumImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: AppColors.navy950.withValues(alpha: 0.82),
    transitionDuration: AppMotion.panel,
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
      child: child,
    ),
    pageBuilder: (context, _, _) => _Celebration(result: result),
  );
}

class _Celebration extends StatelessWidget {
  const _Celebration({required this.result});

  final CompletionResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final badges = result.newBadges;
    final title = result.leveledUp
        ? '¡Subiste al nivel ${result.level}!'
        : badges.length == 1
        ? '¡Nueva insignia!'
        : '¡Nuevas insignias!';
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RippleBurst(
                  color: AppColors.accentBright,
                  size: 112,
                  child: PopIn(
                    child: Container(
                      width: 112,
                      height: 112,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                      child: result.leveledUp
                          ? Text(
                              '${result.level}',
                              style: text.headlineLarge?.copyWith(
                                fontSize: 48,
                                color: AppColors.onNavy,
                              ),
                            )
                          : const Icon(
                              Icons.workspace_premium_rounded,
                              size: 56,
                              color: AppColors.onNavy,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                FadeUp(
                  delay: const Duration(milliseconds: 220),
                  child: Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(
                        color: AppColors.onNavy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeUp(
                  delay: const Duration(milliseconds: 320),
                  child: Text(
                    [
                      'Sumaste ${result.xpAwarded} XP con este reto.',
                      if (result.leveledUp && badges.isNotEmpty)
                        badges.length == 1
                            ? 'Además ganaste la insignia ${badges.first}.'
                            : 'Además ganaste ${badges.length} insignias.',
                    ].join(' '),
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(
                      height: 1.5,
                      color: AppColors.onNavyMuted,
                    ),
                  ),
                ),
                if (badges.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  FadeUp(
                    delay: const Duration(milliseconds: 420),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final badge in badges)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.onNavy.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                            ),
                            child: Text(
                              badge,
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onNavy,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxxl),
                FadeUp(
                  delay: const Duration(milliseconds: 520),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      autofocus: true,
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.onNavy,
                        foregroundColor: AppColors.navy950,
                      ),
                      child: const Text('Seguir mi camino'),
                    ),
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
