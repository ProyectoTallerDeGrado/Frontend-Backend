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

_VentureDto _$VentureDtoFromJson(Map<String, dynamic> json) => _VentureDto(
  emprendimientoId: (json['emprendimiento_id'] as num).toInt(),
  nombre: json['nombre'] as String,
  etapaActual: json['etapa_actual'] == null
      ? null
      : StageDto.fromJson(json['etapa_actual'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VentureDtoToJson(_VentureDto instance) =>
    <String, dynamic>{
      'emprendimiento_id': instance.emprendimientoId,
      'nombre': instance.nombre,
      'etapa_actual': instance.etapaActual,
    };
