// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mentoring_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommitmentDto _$CommitmentDtoFromJson(Map<String, dynamic> json) =>
    _CommitmentDto(
      compromisoId: (json['compromiso_id'] as num).toInt(),
      sesionId: (json['sesion_id'] as num).toInt(),
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String?,
      fechaLimite: json['fecha_limite'] == null
          ? null
          : DateTime.parse(json['fecha_limite'] as String),
    );

Map<String, dynamic> _$CommitmentDtoToJson(_CommitmentDto instance) =>
    <String, dynamic>{
      'compromiso_id': instance.compromisoId,
      'sesion_id': instance.sesionId,
      'descripcion': instance.descripcion,
      'estado': instance.estado,
      'fecha_limite': instance.fechaLimite?.toIso8601String(),
    };

_ProgressDto _$ProgressDtoFromJson(Map<String, dynamic> json) => _ProgressDto(
  seguimientoId: (json['seguimiento_id'] as num).toInt(),
  observaciones: json['observaciones'] as String?,
  fecha: json['fecha'] == null ? null : DateTime.parse(json['fecha'] as String),
  referenciaCliente: json['referencia_cliente'] as String?,
);

Map<String, dynamic> _$ProgressDtoToJson(_ProgressDto instance) =>
    <String, dynamic>{
      'seguimiento_id': instance.seguimientoId,
      'observaciones': instance.observaciones,
      'fecha': instance.fecha?.toIso8601String(),
      'referencia_cliente': instance.referenciaCliente,
    };

_SyncResultDto _$SyncResultDtoFromJson(Map<String, dynamic> json) =>
    _SyncResultDto(
      avances:
          (json['avances'] as List<dynamic>?)
              ?.map((e) => ProgressDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ProgressDto>[],
      compromisos:
          (json['compromisos'] as List<dynamic>?)
              ?.map((e) => CommitmentDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CommitmentDto>[],
      errores:
          (json['errores'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$SyncResultDtoToJson(_SyncResultDto instance) =>
    <String, dynamic>{
      'avances': instance.avances,
      'compromisos': instance.compromisos,
      'errores': instance.errores,
    };
