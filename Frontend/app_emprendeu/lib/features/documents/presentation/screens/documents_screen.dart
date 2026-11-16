import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../../auth/index.dart';
import '../../../ventures/index.dart';
import '../../domain/entities/evidence.dart';
import '../controllers/documents_providers.dart';
import '../../../../shared/widgets/state_views.dart';

/// Documentos del emprendimiento: ver, subir y eliminar los propios (CU30).
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venture = ref.watch(myVentureProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Documentos')),
      body: SafeArea(
        child: venture.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              error is Failure ? error.message : 'No se pudo cargar.',
            ),
          ),
          data: (v) => v == null
              ? const Center(
                  child: Text('Aún no registraste tu emprendimiento.'),
                )
              : _Documents(ventureId: v.id),
        ),
      ),
    );
  }
}

class _Documents extends ConsumerStatefulWidget {
  const _Documents({required this.ventureId});

  final int ventureId;

  @override
  ConsumerState<_Documents> createState() => _DocumentsState();
}

class _DocumentsState extends ConsumerState<_Documents> {
  bool _busy = false;

  /// Documento que se está descargando para abrirlo.
  int? _opening;

  void _say(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _upload() async {
    final file = await ref.read(evidencePickerProvider).pick();
    if (file == null) return;
    setState(() => _busy = true);
    final result = await ref.read(uploadEvidenceUseCaseProvider)(
      ventureId: widget.ventureId,
      file: file,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    final failure = result.failureOrNull;
    if (failure == null) ref.invalidate(ventureEvidenceProvider);
    _say(failure?.message ?? 'Documento subido: ${file.name}.');
  }

  Future<void> _open(Evidence doc) async {
    if (_opening != null) return;
    setState(() => _opening = doc.id);
    final result = await ref.read(openDocumentUseCaseProvider)(doc);
    if (!mounted) return;
    setState(() => _opening = null);
    final failure = result.failureOrNull;
    if (failure != null) _say(failure.message);
  }

  Future<void> _delete(Evidence doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('¿Eliminar «${doc.name}»? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await ref.read(deleteDocumentUseCaseProvider)(doc.id);
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure == null) ref.invalidate(ventureEvidenceProvider);
    _say(failure?.message ?? 'Documento eliminado.');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final docs = ref.watch(ventureEvidenceProvider(widget.ventureId));
    final myId = ref.watch(authControllerProvider).value?.user.id;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ventureEvidenceProvider);
        await ref
            .read(ventureEvidenceProvider(widget.ventureId).future)
            .catchError((_) => <Evidence>[]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Los archivos de tu emprendimiento, incluida la evidencia de tus hitos.',
            style: text.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _upload,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file, size: 20),
              label: const Text('Subir documento'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          docs.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ErrorState(
              message: error is Failure
                  ? error.message
                  : 'No se pudieron cargar los documentos.',
              onRetry: () => ref.invalidate(ventureEvidenceProvider),
            ),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Todavía no hay documentos.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  )
                : Column(
                    children: [
                      for (final d in items)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.blue100),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.name,
                                      style: text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      [
                                        if (d.milestoneId != null)
                                          'Evidencia de hito',
                                        if (d.uploadedAt != null)
                                          relativeTime(d.uploadedAt!),
                                      ].join(' · '),
                                      style: text.bodySmall?.copyWith(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_opening == d.id)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else
                                IconButton(
                                  tooltip: 'Abrir ${d.name}',
                                  onPressed: _opening == null
                                      ? () => _open(d)
                                      : null,
                                  icon: const Icon(Icons.open_in_new),
                                ),
                              if (d.uploadedBy == myId)
                                IconButton(
                                  tooltip: 'Eliminar ${d.name}',
                                  onPressed: () => _delete(d),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
