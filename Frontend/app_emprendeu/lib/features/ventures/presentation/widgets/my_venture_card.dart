import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../ventures_routes.dart';
import '../controllers/ventures_providers.dart';
import 'venture_switcher.dart';

/// «Mi emprendimiento» en el Perfil: datos básicos, el equipo (solo lectura) y
/// accesos a editar y a los hitos. Si el usuario está en varios, permite elegir cuál.
class MyVentureCard extends ConsumerWidget {
  const MyVentureCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final venture = ref.watch(myVentureProvider).value;
    if (venture == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mi emprendimiento', style: text.bodySmall),
          const SizedBox(height: 2),
          Text(venture.name, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            [
              venture.stageName ?? 'Sin etapa',
              if ((venture.sector ?? '').isNotEmpty) venture.sector!,
            ].join(' · '),
            style: text.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          const VentureSwitcher(),
          if (venture.members.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Equipo', style: text.labelLarge),
            const SizedBox(height: 4),
            for (final m in venture.members)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.name,
                        style: text.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      m.roleLabel,
                      style: text.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            Text(
              'El equipo lo arma la coordinación del CIE-U.',
              style: text.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push(VenturesRoutes.edit),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar emprendimiento'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(VenturesRoutes.milestones),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Hitos y evidencia'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
