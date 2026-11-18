import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../gamification_routes.dart';

/// Aviso cuando el emprendedor todavía no tiene puntos ni insignias (CU08).
class XpEmptyState extends StatelessWidget {
  const XpEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aún no tienes puntos ni insignias.', style: text.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Cumple tu primer reto en el Camino para empezar a ganar XP.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.go(GamificationRoutes.journey),
            child: const Text('Ir al Camino'),
          ),
        ],
      ),
    );
  }
}
