import 'package:app_emprendeu/features/auth/data/models/login_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapea la respuesta de /auth/login a entidades', () {
    final dto = LoginResponseDto.fromJson({
      'access_token': 'abc.def.ghi',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'usuario_id': 7,
        'nombre': 'Camila',
        'apellido': 'Justiniano',
        'email': 'camila@correo.com',
        'telefono': null,
        'estado': 'habilitada',
        'rol': 'emprendedor',
        'ultimo_acceso': null,
        'fecha_registro': '2026-10-30T20:16:43Z',
        'permisos': ['ia:consulta', 'ia:registro'],
      },
    });
    final session = dto.toEntity();
    expect(session.accessToken, 'abc.def.ghi');
    expect(session.user.id, 7);
    expect(session.user.fullName, 'Camila Justiniano');
    expect(session.user.isEntrepreneur, isTrue);
    expect(session.user.permisos, ['ia:consulta', 'ia:registro']);
  });
}
