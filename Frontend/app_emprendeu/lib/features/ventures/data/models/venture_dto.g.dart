// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venture_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StageDto _$StageDtoFromJson(Map<String, dynamic> json) =>
    _StageDto(nombre: json['nombre'] as String);

Map<String, dynamic> _$StageDtoToJson(_StageDto instance) => <String, dynamic>{
  'nombre': instance.nombre,
};

_MemberDto _$MemberDtoFromJson(Map<String, dynamic> json) => _MemberDto(
  emprendedorId: (json['emprendedor_id'] as num).toInt(),
  nombre: json['nombre'] as String?,
  apellido: json['apellido'] as String?,
  email: json['email'] as String?,
  rolEnEmprendimiento: json['rol_en_emprendimiento'] as String?,
);

Map<String, dynamic> _$MemberDtoToJson(_MemberDto instance) =>
    <String, dynamic>{
      'emprendedor_id': instance.emprendedorId,
      'nombre': instance.nombre,
      'apellido': instance.apellido,
      'email': instance.email,
      'rol_en_emprendimiento': instance.rolEnEmprendimiento,
    };

_VentureDto _$VentureDtoFromJson(Map<String, dynamic> json) => _VentureDto(
  emprendimientoId: (json['emprendimiento_id'] as num).toInt(),
  nombre: json['nombre'] as String,
  etapaActual: json['etapa_actual'] == null
      ? null
      : StageDto.fromJson(json['etapa_actual'] as Map<String, dynamic>),
  descripcion: json['descripcion'] as String?,
  sector: json['sector'] as String?,
  estado: json['estado'] as String?,
  integrantes:
      (json['integrantes'] as List<dynamic>?)
          ?.map((e) => MemberDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MemberDto>[],
);

Map<String, dynamic> _$VentureDtoToJson(_VentureDto instance) =>
    <String, dynamic>{
      'emprendimiento_id': instance.emprendimientoId,
      'nombre': instance.nombre,
      'etapa_actual': instance.etapaActual,
      'descripcion': instance.descripcion,
      'sector': instance.sector,
      'estado': instance.estado,
      'integrantes': instance.integrantes,
    };
