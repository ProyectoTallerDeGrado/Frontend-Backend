/// Validaciones de los formularios de acceso. Devuelven el mensaje de error
/// o `null` si el valor es válido (contrato de `FormField.validator`).
abstract final class AuthValidators {
  static final _email = RegExp(r'^\S+@\S+\.\S+$');
  static const minPasswordLength = 8;

  static String? requiredName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Este campo es obligatorio.';
    return null;
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu correo electrónico.';
    if (!_email.hasMatch(v)) return 'Ingresa un correo válido.';
    return null;
  }

  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Ingresa tu contraseña.';
    return null;
  }

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Crea una contraseña.';
    if (v.length < minPasswordLength) {
      return 'Usa al menos $minPasswordLength caracteres.';
    }
    return null;
  }

  /// Devuelve un validador que compara con la contraseña original.
  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if ((value ?? '').isEmpty) return 'Repite tu contraseña.';
      if (value != original()) return 'Las contraseñas no coinciden.';
      return null;
    };
  }
}
