import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/evidence.dart';
import '../controllers/documents_providers.dart';

IconData _iconFor(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
  if (RegExp(r'\.(png|jpe?g|webp)$').hasMatch(lower)) {
    return Icons.image_outlined;
  }
  return Icons.description_outlined;
}

/// Documentos del emprendimiento: subir, descargar y eliminar (CU30). El emprendedor
/// solo ve los de su emprendimiento (lo garantiza el servidor).
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key, required this.ventureId});

  final int? ventureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final id = ventureId;
    return Scaffold(
      appBar: AppBar(title: const Text('Documentos')),
      body: SafeArea(
        child: id == null
            ? const Center(child: Text('Aún no registraste tu emprendimiento.'))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ventureEvidenceProvider);
                  await ref
                      .read(ventureEvidenceProvider(id).future)
                      .catchError((_) => <Evidence>[]);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Text(
                      'Archivos de tu emprendimiento: planes, fotos, comprobantes y la evidencia de tus hitos.',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () => _upload(context, ref, id),
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: const Text('Subir documento'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ref
                        .watch(ventureEvidenceProvider(id))
                        .when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, _) => Column(
                            children: [
                              Text(
                                error is Failure
                                    ? error.message
                                    : 'No se pudieron cargar los documentos.',
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    ref.invalidate(ventureEvidenceProvider),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                          data: (items) => items.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Text(
                                    'Todavía no hay documentos.',
                                    textAlign: TextAlign.center,
                                    style: text.bodyMedium?.copyWith(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final d in items) _Tile(document: d),
                                  ],
                                ),
                        ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _upload(BuildContext context, WidgetRef ref, int id) async {
    final file = await ref.read(evidencePickerProvider).pick();
    if (file == null || !context.mounted) return;
    final failure = await ref
        .read(documentsControllerProvider.notifier)
        .upload(ventureId: id, file: file);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure == null ? 'Documento subido.' : failure.message),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.document});

  final Evidence document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final d = document;
    void say(String message) =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.blue100),
        ),
        child: Row(
          children: [
            Icon(_iconFor(d.name), color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (d.milestoneId != null)
                    Text(
                      'Evidencia de un hito',
                      style: text.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Descargar ${d.name}',
              icon: const Icon(Icons.download),
              onPressed: () async {
                final failure = await ref
                    .read(documentsControllerProvider.notifier)
                    .open(d);
                if (failure != null && context.mounted) say(failure.message);
              },
            ),
            IconButton(
              tooltip: 'Eliminar ${d.name}',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dialog) => AlertDialog(
                    title: const Text('Eliminar documento'),
                    content: Text(
                      '¿Eliminar «${d.name}»? No se puede deshacer.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialog).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialog).pop(true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                final failure = await ref
                    .read(documentsControllerProvider.notifier)
                    .delete(d.id);
                if (context.mounted) {
                  say(
                    failure == null ? 'Documento eliminado.' : failure.message,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
