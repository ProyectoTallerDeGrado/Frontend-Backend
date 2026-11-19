import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/auth_user.dart';

part 'auth_user_dto.freezed.dart';
part 'auth_user_dto.g.dart';

/// Usuario tal como lo entrega el backend (`/auth/login` y `/auth/me`).
@freezed
abstract class AuthUserDto with _$AuthUserDto {
  const AuthUserDto._();

  const factory AuthUserDto({
    @JsonKey(name: 'usuario_id') required int usuarioId,
    required String nombre,
    required String apellido,
    required String email,
    String? rol,
    @Default(<String>[]) List<String> permisos,
    @JsonKey(name: 'tutorial_completado_at') DateTime? tutorialCompletadoAt,
  }) = _AuthUserDto;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) =>
      _$AuthUserDtoFromJson(json);

  AuthUser toEntity() => AuthUser(
    id: usuarioId,
    nombre: nombre,
    apellido: apellido,
    email: email,
    rol: rol,
    permisos: permisos,
    tutorialCompletadoAt: tutorialCompletadoAt,
  );
}
