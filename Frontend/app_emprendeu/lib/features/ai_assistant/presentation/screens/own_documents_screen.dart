import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../../documents/index.dart';
import '../../../ventures/index.dart';
import '../../domain/entities/own_document.dart';
import '../../domain/usecases/own_documents_usecases.dart';
import '../controllers/own_documents_providers.dart';

/// «Mis archivos para la IA»: archivos del emprendedor que la IA del celular
/// usa para responder y recomendar. Nunca salen del teléfono.
class OwnDocumentsScreen extends ConsumerWidget {
  const OwnDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final async = ref.watch(ownDocumentsControllerProvider);
    final controller = ref.read(ownDocumentsControllerProvider.notifier);
    final busy = async.value?.adding != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis archivos para la IA')),
      floatingActionButton: async.hasValue
          ? FloatingActionButton.extended(
              onPressed: busy ? null : () => _chooseSource(context, ref),
              icon: const Icon(Icons.upload_file),
              label: const Text('Agregar archivo'),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is Failure
                      ? error.message
                      : 'No se pudieron cargar tus archivos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(ownDocumentsControllerProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (s) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tus archivos se analizan y se guardan solo en este '
                      'celular: no se suben al CIE-U. Pregúntale al Coach por '
                      'ellos, por ejemplo «¿qué mejorarías de mi plan de '
                      'negocio?». Se borran al cerrar sesión.',
                      style: text.bodyMedium?.copyWith(color: AppColors.ink2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (s.adding != null) _Progress(state: s),
            if (s.notice != null)
              _Banner(text: s.notice!, color: AppColors.success),
            if (s.error != null)
              _Banner(text: s.error!, color: AppColors.error),
            if (s.documents.isEmpty && s.adding == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 40,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 8),
                    Text('Aún no agregaste archivos', style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, Word (.docx), TXT o MD, de hasta 20 MB.',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            for (final d in s.documents)
              _DocumentTile(
                document: d,
                enabled: !busy,
                onRemove: () => _confirmRemove(context, d, controller),
              ),
          ],
        ),
      ),
    );
  }

  /// Del teléfono, o de lo que ya subió a su emprendimiento (CU30).
  Future<void> _chooseSource(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(ownDocumentsControllerProvider.notifier);
    final choice = await showModalBottomSheet<_Source>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('Desde tu teléfono'),
              subtitle: const Text('PDF, Word (.docx), TXT o MD'),
              onTap: () => Navigator.pop(context, _Source.phone),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Desde los documentos de tu emprendimiento'),
              subtitle: const Text('Lo que ya subiste al CIE-U'),
              onTap: () => Navigator.pop(context, _Source.venture),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case _Source.phone:
        await controller.pickAndAdd();
      case _Source.venture:
        final picked = await showModalBottomSheet<Evidence>(
          context: context,
          isScrollControlled: true,
          builder: (context) => const _VentureDocumentsSheet(),
        );
        if (picked != null) await controller.addFromVenture(picked);
      case null:
        break;
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    OwnDocument d,
    OwnDocumentsController controller,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quitar este archivo?'),
        content: Text(
          'La IA dejará de usar «${d.name}». El archivo original de tu '
          'teléfono no se borra.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.remove(d.id);
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.state});

  final OwnDocumentsState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final value = state.total == 0 ? null : state.done / state.total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.total == 0
                ? 'Leyendo «${state.adding}»…'
                : 'Analizando «${state.adding}»: ${state.done} de '
                      '${state.total} partes',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppColors.neutralFill,
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
    ),
  );
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.enabled,
    required this.onRemove,
  });

  final OwnDocument document;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final added = document.addedAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(
          document.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            '${document.fragments} partes',
            if (added != null) 'agregado ${relativeTime(added)}',
          ].join(' · '),
        ),
        trailing: IconButton(
          tooltip: 'Quitar ${document.name}',
          onPressed: enabled ? onRemove : null,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

enum _Source { phone, venture }

/// Documentos del emprendimiento que la IA sabe leer.
class _VentureDocumentsSheet extends ConsumerWidget {
  const _VentureDocumentsSheet();

  static bool _readable(Evidence e) =>
      ownDocumentExtensions.contains(e.name.split('.').last.toLowerCase());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final ventureId = ref.watch(currentVentureIdProvider).value;
    Widget message(String m) => Padding(
      padding: const EdgeInsets.all(24),
      child: Text(m, textAlign: TextAlign.center),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Documentos de tu emprendimiento',
                style: text.titleMedium,
              ),
            ),
            if (ventureId == null)
              message('Primero registra tu emprendimiento.')
            else
              Flexible(
                child: ref
                    .watch(ventureEvidenceProvider(ventureId))
                    .when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => message(
                        error is Failure
                            ? error.message
                            : 'No se pudieron cargar los documentos.',
                      ),
                      data: (all) {
                        final docs = all.where(_readable).toList();
                        if (docs.isEmpty) {
                          return message(
                            'No hay documentos que la IA pueda leer '
                            '(PDF, Word .docx, TXT o MD).',
                          );
                        }
                        return ListView(
                          shrinkWrap: true,
                          children: [
                            for (final d in docs)
                              ListTile(
                                leading: const Icon(Icons.description_outlined),
                                title: Text(d.name),
                                onTap: () => Navigator.pop(context, d),
                              ),
                          ],
                        );
                      },
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
