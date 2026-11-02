import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_validators.dart';
import '../widgets/auth_error_banner.dart';

/// Cambio de contraseña desde la pestaña «Perfil». Al terminar, el servidor
/// invalida las sesiones anteriores y esta sigue activa con un token nuevo.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _currentError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
      _currentError = null;
    });
    final failure = await ref
        .read(authControllerProvider.notifier)
        .changePassword(_current.text, _next.text);
    if (!mounted) return;
    if (failure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contraseña actualizada. Las demás sesiones se cerraron.',
          ),
        ),
      );
      context.pop();
      return;
    }
    setState(() {
      _submitting = false;
      if (failure case FieldFailure(field: 'currentPassword')) {
        _currentError = failure.message;
      } else {
        _error = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Al cambiarla se cierran las demás sesiones abiertas con la '
                  'contraseña anterior. Esta sesión sigue activa.',
                  style: text.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 20),
                _PasswordField(
                  label: 'Contraseña actual',
                  controller: _current,
                  autofillHint: AutofillHints.password,
                  validator: AuthValidators.loginPassword,
                  errorText: _currentError,
                ),
                const SizedBox(height: 18),
                _PasswordField(
                  label: 'Contraseña nueva',
                  controller: _next,
                  autofillHint: AutofillHints.newPassword,
                  validator: AuthValidators.differentFrom(() => _current.text),
                ),
                const SizedBox(height: 18),
                _PasswordField(
                  label: 'Repite la contraseña nueva',
                  controller: _confirm,
                  autofillHint: AutofillHints.newPassword,
                  validator: AuthValidators.confirmPassword(() => _next.text),
                  action: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(_error!),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Cambiar contraseña'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo de contraseña sobre fondo claro, con mostrar/ocultar (alto táctil 48).
class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.autofillHint,
    required this.validator,
    this.errorText,
    this.action = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String autofillHint;
  final String? Function(String?) validator;
  final String? errorText;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      validator: widget.validator,
      textInputAction: widget.action,
      autofillHints: [widget.autofillHint],
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        suffixIcon: IconButton(
          tooltip: _obscured ? 'Mostrar contraseña' : 'Ocultar contraseña',
          onPressed: () => setState(() => _obscured = !_obscured),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 22,
          ),
        ),
      ),
    );
  }
}
