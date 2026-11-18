import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';

/// Campo de texto sobre fondo navy (variante del login, `design.md` §4.3).
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.isPassword = false,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool isPassword;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscured = true;

  OutlineInputBorder _border(Color color, [double width = 1.5]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: text.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onNavyLabel,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          obscureText: widget.isPassword && _obscured,
          onFieldSubmitted: widget.onSubmitted,
          cursorColor: AppColors.onNavy,
          style: text.bodyLarge?.copyWith(
            fontSize: 16,
            color: AppColors.onNavy,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: text.bodyLarge?.copyWith(
              fontSize: 16,
              color: AppColors.onNavyHint,
            ),
            filled: true,
            fillColor: AppColors.onNavy.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            enabledBorder: _border(AppColors.onNavy.withValues(alpha: 0.3)),
            focusedBorder: _border(AppColors.onNavy, 2),
            errorBorder: _border(AppColors.accentSoft),
            focusedErrorBorder: _border(AppColors.accentSoft, 2),
            errorStyle: text.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accentSoft,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _obscured
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: () => setState(() => _obscured = !_obscured),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onNavyMuted,
                      size: 22,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
