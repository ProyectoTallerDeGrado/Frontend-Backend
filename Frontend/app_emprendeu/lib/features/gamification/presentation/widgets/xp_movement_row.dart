import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/gamification_profile.dart';

/// Una fila del historial de XP: motivo, cuándo y cantidad.
class XpMovementRow extends StatelessWidget {
  const XpMovementRow({super.key, required this.movement});

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
