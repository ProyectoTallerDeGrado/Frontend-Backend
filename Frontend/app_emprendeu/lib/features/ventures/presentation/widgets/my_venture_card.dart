import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../documents/index.dart';
import '../ventures_routes.dart';
import '../controllers/ventures_providers.dart';

/// «Mi emprendimiento» en el Perfil: datos básicos y accesos a editar y a los hitos.
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
              OutlinedButton.icon(
                onPressed: () => context.push(VenturesRoutes.needs),
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Necesidades y dificultades'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push(DocumentsRoutes.list, extra: venture.id),
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Documentos'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
