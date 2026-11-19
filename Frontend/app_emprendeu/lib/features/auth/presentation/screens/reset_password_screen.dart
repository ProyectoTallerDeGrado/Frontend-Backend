import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../auth_routes.dart';
import '../controllers/auth_providers.dart';
import '../controllers/auth_validators.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

/// Segundo paso (CU01): código recibido por correo y contraseña nueva.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email = ''});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _code.addListener(() {
      if (_codeError != null) setState(() => _codeError = null);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref.read(resetPasswordUseCaseProvider)(
      email: _email.text,
      code: _code.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada. Ya puedes iniciar sesión.'),
        ),
      );
      context.go(AuthRoutes.login);
      return;
    }
    setState(() {
      _submitting = false;
      if (failure case FieldFailure(field: 'code')) {
        _codeError = failure.message;
      } else {
        _error = failure.message;
      }
    });
    if (_codeError != null) _formKey.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AuthScaffold(
      leading: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Volver',
          onPressed: () => context.go(AuthRoutes.forgotPassword),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back, color: AppColors.onNavy),
        ),
      ),
      title: 'Crea una contraseña nueva.',
      subtitle: 'Escribe el código de 6 dígitos que te enviamos. Vence en 15 minutos.',
      form: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: 'Correo electrónico',
                hint: 'tu@correo.com',
                controller: _email,
                validator: AuthValidators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Código de 6 dígitos',
                hint: '123456',
                controller: _code,
                validator: (v) =>
                    _codeError ??
                    (RegExp(r'^\d{6}$').hasMatch((v ?? '').trim())
                        ? null
                        : 'El código tiene 6 dígitos.'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.oneTimeCode],
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Contraseña nueva',
                hint: 'Mínimo 8 caracteres',
                controller: _password,
                isPassword: true,
                validator: AuthValidators.newPassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Confirmar contraseña',
                hint: 'Repite tu contraseña',
                controller: _confirm,
                isPassword: true,
                validator: AuthValidators.confirmPassword(() => _password.text),
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(_error!),
              ],
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Restablecer',
                onPressed: _submit,
                loading: _submitting,
              ),
            ],
          ),
        ),
      ),
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: () => context.go(AuthRoutes.forgotPassword),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: AppColors.onNavy,
              textStyle: text.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Pedir un código nuevo'),
          ),
        ],
      ),
    );
  }
}
