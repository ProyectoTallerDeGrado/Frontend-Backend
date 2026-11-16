import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../auth_routes.dart';
import '../controllers/auth_providers.dart';
import '../controllers/auth_validators.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

/// Primer paso de la recuperación (CU01): pide el código por correo.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref.read(requestPasswordResetUseCaseProvider)(
      _email.text,
    );
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure == null) {
      context.go(
        Uri(
          path: AuthRoutes.resetPassword,
          queryParameters: {'email': _email.text.trim()},
        ).toString(),
      );
      return;
    }
    setState(() {
      _submitting = false;
      _error = failure.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AuthScaffold(
      leading: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Volver al ingreso',
          onPressed: () => context.go(AuthRoutes.login),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back, color: AppColors.onNavy),
        ),
      ),
      title: 'Recupera tu contraseña.',
      subtitle: 'Escribe tu correo y te enviaremos un código de 6 dígitos para crear una nueva.',
      form: Form(
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
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              AuthErrorBanner(_error!),
            ],
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: 'Enviar código',
              onPressed: _submit,
              loading: _submitting,
            ),
          ],
        ),
      ),
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: () => context.go(AuthRoutes.login),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: AppColors.onNavy,
              textStyle: text.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Volver al ingreso'),
          ),
        ],
      ),
    );
  }
}
