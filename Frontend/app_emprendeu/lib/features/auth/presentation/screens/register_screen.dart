import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../auth_routes.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_validators.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;
  // Errores que devuelve el servidor para un campo; se limpian al editarlo.
  String? _emailServerError;
  String? _nameServerError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _email.addListener(() {
      if (_emailServerError != null) setState(() => _emailServerError = null);
    });
    _name.addListener(() {
      if (_nameServerError != null) setState(() => _nameServerError = null);
    });
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(authControllerProvider.notifier)
        .register(
          fullName: _name.text,
          email: _email.text,
          password: _password.text,
        );
    // Si entró, el router cambia de pantalla solo.
    if (!mounted) return;
    setState(() {
      _submitting = false;
      switch (failure) {
        case FieldFailure(field: 'email', :final message):
          _emailServerError = message;
        case FieldFailure(field: 'name', :final message):
          _nameServerError = message;
        case Failure(:final message):
          _error = message;
        case null:
          break;
      }
    });
    if (_emailServerError != null || _nameServerError != null) {
      _formKey.currentState!.validate();
    }
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
      title: 'Crea tu cuenta.',
      subtitle: 'Regístrate para seguir tu progreso y acceder a las mentorías del CIE-U.',
      form: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: 'Nombre completo',
                hint: 'Nombre y apellidos',
                controller: _name,
                validator: (v) =>
                    _nameServerError ?? AuthValidators.requiredName(v),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Correo electrónico',
                hint: 'tu@correo.com',
                controller: _email,
                validator: (v) => _emailServerError ?? AuthValidators.email(v),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Contraseña',
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
                label: 'Crear cuenta',
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
          Text(
            '¿Ya tienes cuenta?',
            style: text.bodyMedium?.copyWith(
              fontSize: 15,
              color: AppColors.onNavyMuted,
            ),
          ),
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
            child: const Text('Inicia sesión'),
          ),
        ],
      ),
    );
  }
}
