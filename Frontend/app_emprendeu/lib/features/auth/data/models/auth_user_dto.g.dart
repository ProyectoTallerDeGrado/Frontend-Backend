// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthUserDto _$AuthUserDtoFromJson(Map<String, dynamic> json) => _AuthUserDto(
  usuarioId: (json['usuario_id'] as num).toInt(),
  nombre: json['nombre'] as String,
  apellido: json['apellido'] as String,
  email: json['email'] as String,
  rol: json['rol'] as String?,
  permisos:
      (json['permisos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  tutorialCompletadoAt: json['tutorial_completado_at'] == null
      ? null
      : DateTime.parse(json['tutorial_completado_at'] as String),
);

Map<String, dynamic> _$AuthUserDtoToJson(
  _AuthUserDto instance,
) => <String, dynamic>{
  'usuario_id': instance.usuarioId,
  'nombre': instance.nombre,
  'apellido': instance.apellido,
  'email': instance.email,
  'rol': instance.rol,
  'permisos': instance.permisos,
  'tutorial_completado_at': instance.tutorialCompletadoAt?.toIso8601String(),
};
