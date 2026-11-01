import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../gamification/index.dart';

/// Tarjeta oscura con el anillo de XP, el nivel y la etapa actual.
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.profile, this.stageName});

  final GamificationProfile profile;
  final String? stageName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final remaining = profile.missingXp;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _Ring(
            xp: profile.xp,
            fraction: (profile.progressPct / 100).clamp(0, 1),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nivel ${profile.level}',
                  style: text.titleLarge?.copyWith(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining == null
                      ? 'Alcanzaste el nivel máximo.'
                      : 'Te faltan $remaining XP para el nivel ${profile.level + 1}.',
                  style: text.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.onNavyMuted,
                  ),
                ),
                if (stageName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.blueRing,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Etapa: $stageName',
                            style: text.bodySmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.xp, required this.fraction});

  final int xp;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: '$xp XP',
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: fraction),
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CustomPaint(
                  size: const Size(104, 104),
                  painter: _RingPainter(value),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$xp',
                  style: text.titleLarge?.copyWith(
                    fontSize: 26,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'XP',
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: AppColors.onNavyMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.42;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..color = AppColors.blueRing
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}
