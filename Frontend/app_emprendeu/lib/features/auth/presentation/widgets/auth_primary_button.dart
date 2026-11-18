import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';

/// Botón principal blanco sobre navy (`design.md` §4.2).
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Muestra un indicador y bloquea el botón mientras se procesa.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.onNavy,
          foregroundColor: AppColors.navy950,
          disabledBackgroundColor: AppColors.onNavy.withValues(alpha: 0.7),
          disabledForegroundColor: AppColors.navy950,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.navy950,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }
}
