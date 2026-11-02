// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MilestoneDto _$MilestoneDtoFromJson(Map<String, dynamic> json) =>
    _MilestoneDto(
      hitoId: (json['hito_id'] as num).toInt(),
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String?,
      fechaEstimada: json['fecha_estimada'] == null
          ? null
          : DateTime.parse(json['fecha_estimada'] as String),
      fechaCumplimiento: json['fecha_cumplimiento'] == null
          ? null
          : DateTime.parse(json['fecha_cumplimiento'] as String),
    );

Map<String, dynamic> _$MilestoneDtoToJson(_MilestoneDto instance) =>
    <String, dynamic>{
      'hito_id': instance.hitoId,
      'titulo': instance.titulo,
      'descripcion': instance.descripcion,
      'estado': instance.estado,
      'fecha_estimada': instance.fechaEstimada?.toIso8601String(),
      'fecha_cumplimiento': instance.fechaCumplimiento?.toIso8601String(),
    };
