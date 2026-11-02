// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HistoryEventDto _$HistoryEventDtoFromJson(Map<String, dynamic> json) =>
    _HistoryEventDto(
      tipo: json['tipo'] as String,
      referenciaId: (json['referencia_id'] as num).toInt(),
      fecha: json['fecha'] == null
          ? null
          : DateTime.parse(json['fecha'] as String),
      titulo: json['titulo'] as String,
      detalle: json['detalle'] as String?,
      estado: json['estado'] as String?,
      autor: json['autor'] as String?,
    );

Map<String, dynamic> _$HistoryEventDtoToJson(_HistoryEventDto instance) =>
    <String, dynamic>{
      'tipo': instance.tipo,
      'referencia_id': instance.referenciaId,
      'fecha': instance.fecha?.toIso8601String(),
      'titulo': instance.titulo,
      'detalle': instance.detalle,
      'estado': instance.estado,
      'autor': instance.autor,
    };
