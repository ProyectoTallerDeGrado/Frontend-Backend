import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/venture.dart';
import '../controllers/ventures_providers.dart';

/// Editar el emprendimiento propio (CU05). El estado no aparece: lo fija la coordinación.
class EditVentureScreen extends ConsumerWidget {
  const EditVentureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venture = ref.watch(myVentureProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi emprendimiento')),
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
              : _EditForm(venture: v),
        ),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.venture});

  final Venture venture;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final _name = TextEditingController(text: widget.venture.name);
  late final _sector = TextEditingController(text: widget.venture.sector ?? '');
  late final _description = TextEditingController(
    text: widget.venture.description ?? '',
  );
  bool _saving = false;
  String? _nameError;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _sector.dispose();
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
    final result = await ref.read(updateVentureUseCaseProvider)(
      widget.venture.id,
      name: _name.text,
      description: _description.text,
      sector: _sector.text,
    );
    if (!mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(myVenturesProvider);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
        context.pop();
      case Err(:final failure):
        setState(() {
          _saving = false;
          if (failure is FieldFailure && failure.field == 'name') {
            _nameError = failure.message;
          } else {
            _error = failure.message;
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: 'Nombre del emprendimiento',
            errorText: _nameError,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _sector,
          decoration: const InputDecoration(
            labelText: 'Sector',
            helperText: 'Por ejemplo: textil, alimentos, tecnología.',
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _description,
          decoration: const InputDecoration(labelText: 'Descripción'),
          minLines: 3,
          maxLines: 6,
        ),
        const SizedBox(height: 10),
        Text(
          'Etapa: ${widget.venture.stageName ?? 'Sin etapa'}'
          '${widget.venture.status == null ? '' : ' · Estado: ${widget.venture.status}'}. '
          'La etapa y el estado los define la coordinación.',
          style: text.bodySmall?.copyWith(color: AppColors.muted),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: text.bodyMedium?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar cambios'),
          ),
        ),
      ],
    );
  }
}
