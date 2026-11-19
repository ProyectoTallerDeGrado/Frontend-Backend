import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../domain/entities/gamification_profile.dart';

/// XP total, nivel y barra de avance hacia el siguiente nivel.
class XpLevelCard extends StatelessWidget {
  const XpLevelCard({super.key, required this.profile});

  final GamificationProfile profile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = profile;
    return Container(
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
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (p.progressPct / 100).clamp(0, 1)),
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : AppMotion.celebrate,
              curve: AppMotion.enter,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                semanticsLabel: 'Avance hacia el siguiente nivel',
              ),
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
    );
  }
}
