import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/venture_need.dart';
import '../../domain/usecases/needs_usecases.dart';
import '../controllers/needs_providers.dart';

/// Formulario para reportar una necesidad o dificultad (CU24).
class ReportNeedScreen extends ConsumerStatefulWidget {
  const ReportNeedScreen({super.key});

  @override
  ConsumerState<ReportNeedScreen> createState() => _ReportNeedScreenState();
}

class _ReportNeedScreenState extends ConsumerState<ReportNeedScreen> {
  final _description = TextEditingController();
  NeedKind _kind = NeedKind.need;
  NeedPriority _priority = NeedPriority.medium;
  int? _categoryId;
  bool _sending = false;
  String? _categoryError;
  String? _descriptionError;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _categoryError = _descriptionError = _error = null;
    });
    final failure = await ref
        .read(needsControllerProvider.notifier)
        .report(
          categoryId: _categoryId,
          kind: _kind,
          priority: _priority,
          description: _description.text,
        );
    if (!mounted) return;
    if (failure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado. El CIE-U lo podrá ver.'),
        ),
      );
      context.pop();
      return;
    }
    setState(() {
      _sending = false;
      if (failure is FieldFailure && failure.field == 'category') {
        _categoryError = failure.message;
      } else if (failure is FieldFailure && failure.field == 'description') {
        _descriptionError = failure.message;
      } else {
        _error = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final categories = ref.watch(needCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text('¿Qué quieres reportar?', style: text.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<NeedKind>(
              segments: const [
                ButtonSegment(value: NeedKind.need, label: Text('Necesidad')),
                ButtonSegment(
                  value: NeedKind.difficulty,
                  label: Text('Dificultad'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 18),
            Text('Rubro', style: text.titleSmall),
            const SizedBox(height: 8),
            categories.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error is Failure
                        ? error.message
                        : 'No se pudieron cargar los rubros.',
                  ),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(needCategoriesProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
              data: (items) => items.isEmpty
                  ? Text(
                      'El CIE-U todavía no definió rubros. Intenta más tarde '
                      'o consulta a tu asesor.',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted),
                    )
                  : DropdownButtonFormField<int>(
                      initialValue: _categoryId,
                      isExpanded: true,
                      hint: const Text('Elige un rubro'),
                      decoration: InputDecoration(errorText: _categoryError),
                      items: [
                        for (final c in items)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (id) => setState(() => _categoryId = id),
                    ),
            ),
            const SizedBox(height: 18),
            Text('Prioridad', style: text.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<NeedPriority>(
              segments: const [
                ButtonSegment(value: NeedPriority.low, label: Text('Baja')),
                ButtonSegment(value: NeedPriority.medium, label: Text('Media')),
                ButtonSegment(value: NeedPriority.high, label: Text('Alta')),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _description,
              minLines: 4,
              maxLines: 8,
              maxLength: maxNeedDescriptionLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Descríbelo',
                hintText: 'Cuéntanos con tus palabras qué ocurre.',
                alignLabelWithHint: true,
                errorText: _descriptionError,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: text.bodyMedium?.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _sending ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar reporte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
