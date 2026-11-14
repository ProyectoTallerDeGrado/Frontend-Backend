import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/local_ai_progress.dart';
import '../../domain/entities/local_ai_status.dart';
import '../assistant_routes.dart';
import '../controllers/local_ai_providers.dart';

/// Tarjeta «IA en tu celular» de la pestaña Perfil: descargar, ver el avance,
/// cancelar y eliminar la IA local.
class LocalAiSection extends ConsumerWidget {
  const LocalAiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final async = ref.watch(localAiControllerProvider);
    final controller = ref.read(localAiControllerProvider.notifier);

    Widget body(LocalAiState s) {
      final children = <Widget>[];
      switch (s.status) {
        case LocalAiStatus.unsupported:
          children.add(
            Text(
              'Este dispositivo todavía no puede usar la IA sin conexión. '
              'Puedes seguir usando el Coach con internet.',
              style: text.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          );
        case LocalAiStatus.installed:
          children.addAll([
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Instalada en tu celular',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(AssistantRoutes.ownFiles),
              icon: const Icon(Icons.folder_special_outlined, size: 18),
              label: const Text('Mis archivos para la IA'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: s.busy
                  ? null
                  : () => _confirmRemove(context, s, controller),
              icon: s.busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, size: 18),
              label: Text(s.busy ? 'Eliminando…' : 'Eliminar del celular'),
            ),
          ]);
        case LocalAiStatus.notInstalled when s.downloading:
          final p = s.progress!;
          children.addAll([
            Text(
              p.step == LocalAiStep.embedder
                  ? 'Descargando el buscador de documentos…'
                  : 'Descargando el modelo de IA…',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: p.percent / 100,
                minHeight: 8,
                backgroundColor: AppColors.neutralFill,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${p.percent} % · Mantén la app abierta',
              style: text.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: controller.cancel,
              child: const Text('Cancelar descarga'),
            ),
          ]);
        case LocalAiStatus.notInstalled:
          children.addAll([
            Text(
              'Descarga la IA para usar el Coach sin internet. Tus archivos '
              'se analizarán solo en tu celular.',
              style: text.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => _confirmDownload(context, s, controller),
              icon: const Icon(Icons.download, size: 18),
              label: Text('Descargar IA (${formatBytes(s.downloadBytes)})'),
            ),
          ]);
      }
      if (s.error != null) {
        children.addAll([
          const SizedBox(height: 8),
          Text(
            s.error!,
            style: text.bodySmall?.copyWith(color: AppColors.error),
          ),
        ]);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('IA en tu celular', style: text.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(localAiErrorText(error)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ref.invalidate(localAiControllerProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
            data: body,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDownload(
    BuildContext context,
    LocalAiState s,
    LocalAiController controller,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descargar la IA?'),
        content: Text(
          'Se descargarán ${formatBytes(s.downloadBytes)}. Te recomendamos usar '
          'Wi‑Fi y tener al menos ${formatBytes(s.downloadBytes * 2)} libres. '
          'Si se corta, puedes continuar después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.download();
  }

  Future<void> _confirmRemove(
    BuildContext context,
    LocalAiState s,
    LocalAiController controller,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar la IA del celular?'),
        content: Text(
          'Liberarás unos ${formatBytes(s.downloadBytes)}. El Coach seguirá '
          'funcionando con internet y podrás volver a descargarla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.remove();
  }
}
