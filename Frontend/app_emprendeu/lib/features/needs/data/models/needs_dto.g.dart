// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'needs_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NeedCategoryDto _$NeedCategoryDtoFromJson(Map<String, dynamic> json) =>
    _NeedCategoryDto(
      necesidadId: (json['necesidad_id'] as num).toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );

Map<String, dynamic> _$NeedCategoryDtoToJson(_NeedCategoryDto instance) =>
    <String, dynamic>{
      'necesidad_id': instance.necesidadId,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
    };

_VentureNeedDto _$VentureNeedDtoFromJson(Map<String, dynamic> json) =>
    _VentureNeedDto(
      id: (json['emprendimiento_necesidad_id'] as num).toInt(),
      necesidadId: (json['necesidad_id'] as num).toInt(),
      necesidad: json['necesidad'] as String,
      estado: json['estado'] as String?,
      prioridad: json['prioridad'] as String?,
      tipo: json['tipo'] as String? ?? 'necesidad',
      descripcion: json['descripcion'] as String?,
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
      'necesidad_id': instance.necesidadId,
      'necesidad': instance.necesidad,
      'estado': instance.estado,
      'prioridad': instance.prioridad,
      'tipo': instance.tipo,
      'descripcion': instance.descripcion,
      'fecha_detectada': instance.fechaDetectada?.toIso8601String(),
      'fecha_resuelta': instance.fechaResuelta?.toIso8601String(),
    };
