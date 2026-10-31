import 'package:app_emprendeu/features/auth/presentation/controllers/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email', () {
    expect(AuthValidators.email(''), isNotNull);
    expect(AuthValidators.email('abc'), 'Ingresa un correo válido.');
    expect(AuthValidators.email(' a@b.co '), isNull);
  });

  test('newPassword exige 8 caracteres', () {
    expect(AuthValidators.newPassword('1234567'), isNotNull);
    expect(AuthValidators.newPassword('12345678'), isNull);
  });

  test('confirmPassword compara con la original', () {
    final v = AuthValidators.confirmPassword(() => 'abcdefgh');
    expect(v('abcdefgx'), 'Las contraseñas no coinciden.');
    expect(v('abcdefgh'), isNull);
  });
}
