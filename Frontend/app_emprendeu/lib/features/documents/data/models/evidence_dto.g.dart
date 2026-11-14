// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EvidenceDto _$EvidenceDtoFromJson(Map<String, dynamic> json) => _EvidenceDto(
  documentoId: (json['documento_id'] as num).toInt(),
  nombre: json['nombre'] as String,
  tipo: json['tipo'] as String?,
  hitoId: (json['hito_id'] as num?)?.toInt(),
  usuarioId: (json['usuario_id'] as num?)?.toInt(),
  fechaSubida: json['fecha_subida'] == null
      ? null
      : DateTime.parse(json['fecha_subida'] as String),
);

Map<String, dynamic> _$EvidenceDtoToJson(_EvidenceDto instance) =>
    <String, dynamic>{
      'documento_id': instance.documentoId,
      'nombre': instance.nombre,
      'tipo': instance.tipo,
      'hito_id': instance.hitoId,
      'usuario_id': instance.usuarioId,
      'fecha_subida': instance.fechaSubida?.toIso8601String(),
    };
