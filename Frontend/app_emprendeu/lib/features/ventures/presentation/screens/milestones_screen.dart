import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../../documents/index.dart';
import '../../domain/entities/milestone.dart';
import '../controllers/ventures_providers.dart';

/// Hitos del emprendimiento con su evidencia (CU20).
class MilestonesScreen extends ConsumerWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venture = ref.watch(myVentureProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hitos y evidencia')),
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
              : _Milestones(ventureId: v.id),
        ),
      ),
    );
  }
}

class _Milestones extends ConsumerWidget {
  const _Milestones({required this.ventureId});

  final int ventureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final milestones = ref.watch(milestonesProvider(ventureId));
    final evidence = ref.watch(ventureEvidenceProvider(ventureId)).value ?? [];
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(milestonesProvider)
          ..invalidate(ventureEvidenceProvider);
        await ref
            .read(milestonesProvider(ventureId).future)
            .catchError((_) => <Milestone>[]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Registra lo que logras y, si quieres, adjunta una foto o documento como evidencia.',
            style: text.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _openNewSheet(context, ventureId),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Registrar hito'),
            ),
          ),
          const SizedBox(height: 16),
          milestones.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Column(
              children: [
                Text(
                  error is Failure
                      ? error.message
                      : 'No se pudieron cargar los hitos.',
                ),
                OutlinedButton(
                  onPressed: () => ref.invalidate(milestonesProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Todavía no registraste hitos.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  )
                : Column(
                    children: [
                      for (final h in items)
                        _MilestoneCard(
                          ventureId: ventureId,
                          milestone: h,
                          files: [
                            for (final e in evidence)
                              if (e.milestoneId == h.id) e,
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

void _snack(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

class _MilestoneCard extends ConsumerWidget {
  const _MilestoneCard({
    required this.ventureId,
    required this.milestone,
    required this.files,
  });

  final int ventureId;
  final Milestone milestone;
  final List<Evidence> files;

  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final file = await ref.read(evidencePickerProvider).pick();
    if (file == null || !context.mounted) return;
    final failure = await ref
        .read(milestonesControllerProvider.notifier)
        .attach(ventureId: ventureId, milestoneId: milestone.id, file: file);
    if (!context.mounted) return;
    _snack(context, failure == null ? 'Evidencia subida.' : failure.message);
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final failure = await ref
        .read(milestonesControllerProvider.notifier)
        .complete(milestone.id);
    if (!context.mounted) return;
    _snack(context, failure == null ? 'Hito cumplido.' : failure.message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final done = milestone.done;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.blue100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.flag_outlined,
                  size: 20,
                  color: done ? AppColors.successDark : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    milestone.title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if ((milestone.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(milestone.description!, style: text.bodyMedium),
            ],
            const SizedBox(height: 6),
            Text(
              done
                  ? 'Cumplido${milestone.doneAt == null ? '' : ' · ${relativeTime(milestone.doneAt!)}'}'
                  : 'Pendiente',
              style: text.bodySmall?.copyWith(color: AppColors.muted),
            ),
            if (files.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final f in files)
                    Chip(
                      avatar: const Icon(Icons.attach_file, size: 16),
                      label: Text(f.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _attach(context, ref),
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Adjuntar evidencia'),
                ),
                if (!done)
                  TextButton(
                    onPressed: () => _complete(context, ref),
                    child: const Text('Marcar cumplido'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openNewSheet(BuildContext context, int ventureId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NewMilestoneSheet(ventureId: ventureId),
    );

class _NewMilestoneSheet extends ConsumerStatefulWidget {
  const _NewMilestoneSheet({required this.ventureId});

  final int ventureId;

  @override
  ConsumerState<_NewMilestoneSheet> createState() => _NewMilestoneSheetState();
}

class _NewMilestoneSheetState extends ConsumerState<_NewMilestoneSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  PickedFile? _file;
  bool _saving = false;
  String? _titleError;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ref.read(evidencePickerProvider).pick();
    if (file != null && mounted) setState(() => _file = file);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _titleError = null;
      _error = null;
    });
    final outcome = await ref
        .read(milestonesControllerProvider.notifier)
        .create(
          ventureId: widget.ventureId,
          title: _title.text,
          description: _description.text,
          file: _file,
        );
    if (!mounted) return;
    if (!outcome.saved) {
      final failure = outcome.failure!;
      setState(() {
        _saving = false;
        if (failure is FieldFailure && failure.field == 'title') {
          _titleError = failure.message;
        } else {
          _error = failure.message;
        }
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome.evidenceFailure == null
              ? 'Hito registrado.'
              : 'Hito registrado, pero no se pudo subir la evidencia: '
                    '${outcome.evidenceFailure!.message} Puedes adjuntarla desde el hito.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Registrar hito', style: text.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: 'Qué lograste',
                errorText: _titleError,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
              minLines: 2,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pick,
              icon: const Icon(Icons.attach_file, size: 18),
              label: Text(
                _file == null
                    ? 'Adjuntar evidencia (opcional)'
                    : 'Evidencia: ${_file!.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: text.bodyMedium?.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar hito'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
