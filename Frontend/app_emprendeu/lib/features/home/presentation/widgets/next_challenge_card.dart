import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../gamification/index.dart';

/// «Siguiente reto» con acceso directo al camino.
class NextChallengeCard extends StatelessWidget {
  const NextChallengeCard({
    super.key,
    required this.journey,
    required this.onOpenJourney,
  });

  final Journey journey;
  final VoidCallback onOpenJourney;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final next = journey.nextChallenge;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SIGUIENTE RETO',
                style: text.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.muted,
                ),
              ),
              if (next != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${next.xp} XP',
                    style: text.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentOn,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            next?.title ?? '¡Completaste todos los retos del programa!',
            style: text.titleMedium?.copyWith(fontSize: 18, height: 1.3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onOpenJourney,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Ver en mi camino'),
              iconAlignment: IconAlignment.end,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: text.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
