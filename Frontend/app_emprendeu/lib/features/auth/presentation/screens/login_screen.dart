import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../auth_routes.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_validators.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(authControllerProvider.notifier)
        .login(_email.text, _password.text);
    // Si entró, el router cambia de pantalla solo.
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = failure?.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AuthScaffold(
      title: 'Tu emprendimiento, acompañado.',
      subtitle: 'Sigue tu progreso, conversa con tu coach de IA y agenda mentorías con el CIE-U.',
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
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Contraseña',
                hint: '••••••••••',
                controller: _password,
                isPassword: true,
                validator: AuthValidators.loginPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(_error!),
              ],
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: 'Ingresar',
                onPressed: _submit,
                loading: _submitting,
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AuthRoutes.forgotPassword),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: AppColors.onNavyMuted,
                    textStyle: text.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
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
            '¿Primera vez?',
            style: text.bodyMedium?.copyWith(
              fontSize: 15,
              color: AppColors.onNavyMuted,
            ),
          ),
          TextButton(
            onPressed: () => context.go(AuthRoutes.register),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: AppColors.onNavy,
              textStyle: text.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Regístrate'),
          ),
        ],
      ),
    );
  }
}
