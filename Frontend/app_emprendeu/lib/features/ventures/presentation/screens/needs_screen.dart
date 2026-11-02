import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/venture_need.dart';
import '../controllers/ventures_providers.dart';

const _priorityLabels = {'baja': 'Baja', 'media': 'Media', 'alta': 'Alta'};

/// Necesidades y dificultades del emprendimiento (CU24).
class NeedsScreen extends ConsumerWidget {
  const NeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venture = ref.watch(myVentureProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Necesidades y dificultades')),
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
              : _Needs(ventureId: v.id),
        ),
      ),
    );
  }
}

class _Needs extends ConsumerWidget {
  const _Needs({required this.ventureId});

  final int ventureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final needs = ref.watch(needsProvider(ventureId));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(needsProvider);
        await ref
            .read(needsProvider(ventureId).future)
            .catchError((_) => <VentureNeed>[]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Cuéntanos qué necesitas o qué se te está dificultando para que tu mentor y el CIE-U puedan ayudarte.',
            style: text.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _NewNeedSheet(ventureId: ventureId),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Registrar necesidad'),
            ),
          ),
          const SizedBox(height: 16),
          needs.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Column(
              children: [
                Text(
                  error is Failure
                      ? error.message
                      : 'No se pudieron cargar tus necesidades.',
                ),
                OutlinedButton(
                  onPressed: () => ref.invalidate(needsProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Todavía no registraste necesidades.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  )
                : Column(children: [for (final n in items) _NeedCard(n)]),
          ),
        ],
      ),
    );
  }
}

class _NeedCard extends ConsumerWidget {
  const _NeedCard(this.need);

  final VentureNeed need;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
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
                  need.resolved ? Icons.check_circle : Icons.help_outline,
                  size: 20,
                  color: need.resolved
                      ? AppColors.successDark
                      : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    need.name,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              [
                need.resolved ? 'Resuelta' : 'Sin resolver',
                'Prioridad ${_priorityLabels[need.priority] ?? need.priority}',
                if (need.detectedAt != null)
                  'Registrada ${relativeTime(need.detectedAt!)}',
              ].join(' · '),
              style: text.bodySmall?.copyWith(color: AppColors.muted),
            ),
            if (!need.resolved)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    final failure = await ref
                        .read(needsControllerProvider.notifier)
                        .resolve(need.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            failure == null
                                ? 'Marcada como resuelta.'
                                : failure.message,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Marcar como resuelta'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewNeedSheet extends ConsumerStatefulWidget {
  const _NewNeedSheet({required this.ventureId});

  final int ventureId;

  @override
  ConsumerState<_NewNeedSheet> createState() => _NewNeedSheetState();
}

class _NewNeedSheetState extends ConsumerState<_NewNeedSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _priority = 'media';
  bool _saving = false;
  String? _nameError;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _nameError = null;
      _error = null;
    });
    final failure = await ref
        .read(needsControllerProvider.notifier)
        .add(
          ventureId: widget.ventureId,
          name: _name.text,
          priority: _priority,
          description: _description.text,
        );
    if (!mounted) return;
    if (failure == null) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Necesidad registrada.')),
      );
      return;
    }
    setState(() {
      _saving = false;
      if (failure is FieldFailure && failure.field == 'name') {
        _nameError = failure.message;
      } else {
        _error = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final typed = _name.text.trim().toLowerCase();
    final suggestions = [
      for (final s in ref.watch(needCatalogProvider).value ?? const <String>[])
        if (typed.isNotEmpty &&
            s.toLowerCase().contains(typed) &&
            s.toLowerCase() != typed)
          s,
    ].take(4).toList();
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
            Text('Registrar necesidad', style: text.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Qué necesitas o qué te cuesta',
                errorText: _nameError,
              ),
              textInputAction: TextInputAction.next,
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in suggestions)
                    ActionChip(
                      label: Text(s),
                      onPressed: () => setState(() => _name.text = s),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Detalle (opcional)',
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Text('Prioridad', style: text.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final p in _priorityLabels.entries)
                  ChoiceChip(
                    label: Text(p.value),
                    selected: _priority == p.key,
                    onSelected: (_) => setState(() => _priority = p.key),
                  ),
              ],
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
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
