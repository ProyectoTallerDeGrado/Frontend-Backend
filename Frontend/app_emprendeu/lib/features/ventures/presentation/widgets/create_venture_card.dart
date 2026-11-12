import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/result.dart';
import '../controllers/ventures_providers.dart';

/// Estado vacío: el emprendedor aún no registró su emprendimiento.
/// Sin él no hay camino de retos ni compromisos.
class CreateVentureCard extends ConsumerStatefulWidget {
  const CreateVentureCard({super.key, this.onCreated});

  final VoidCallback? onCreated;

  @override
  ConsumerState<CreateVentureCard> createState() => _CreateVentureCardState();
}

class _CreateVentureCardState extends ConsumerState<CreateVentureCard> {
  final _name = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(createVentureUseCaseProvider)(_name.text);
    if (!mounted) return;
    switch (result) {
      case Ok():
        ref.invalidate(myVenturesProvider);
        widget.onCreated?.call();
      case Err(:final failure):
        setState(() {
          _saving = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registra tu emprendimiento', style: text.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Con él se activa tu camino de retos, tus compromisos y las mentorías.',
            style: text.bodyMedium?.copyWith(
              fontSize: 14,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Nombre del emprendimiento',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Registrar emprendimiento'),
            ),
          ),
        ],
      ),
    );
  }
}
