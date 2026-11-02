// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'need_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VentureNeedDto _$VentureNeedDtoFromJson(Map<String, dynamic> json) =>
    _VentureNeedDto(
      id: (json['emprendimiento_necesidad_id'] as num).toInt(),
      necesidad: json['necesidad'] as String,
      estado: json['estado'] as String?,
      prioridad: json['prioridad'] as String?,
      fechaDetectada: json['fecha_detectada'] == null
          ? null
          : DateTime.parse(json['fecha_detectada'] as String),
      fechaResuelta: json['fecha_resuelta'] == null
          ? null
          : DateTime.parse(json['fecha_resuelta'] as String),
    );

Map<String, dynamic> _$VentureNeedDtoToJson(_VentureNeedDto instance) =>
    <String, dynamic>{
      'emprendimiento_necesidad_id': instance.id,
      'necesidad': instance.necesidad,
      'estado': instance.estado,
      'prioridad': instance.prioridad,
      'fecha_detectada': instance.fechaDetectada?.toIso8601String(),
      'fecha_resuelta': instance.fechaResuelta?.toIso8601String(),
    };

_NeedCatalogDto _$NeedCatalogDtoFromJson(Map<String, dynamic> json) =>
    _NeedCatalogDto(nombre: json['nombre'] as String);

Map<String, dynamic> _$NeedCatalogDtoToJson(_NeedCatalogDto instance) =>
    <String, dynamic>{'nombre': instance.nombre};
