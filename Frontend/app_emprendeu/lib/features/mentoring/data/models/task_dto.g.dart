// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskDto _$TaskDtoFromJson(Map<String, dynamic> json) => _TaskDto(
  tipo: json['tipo'] as String,
  referenciaId: (json['referencia_id'] as num).toInt(),
  emprendimientoId: (json['emprendimiento_id'] as num).toInt(),
  titulo: json['titulo'] as String,
  detalle: json['detalle'] as String?,
  responsable: json['responsable'] as String?,
  estado: json['estado'] as String,
  fechaPrevista: json['fecha_prevista'] == null
      ? null
      : DateTime.parse(json['fecha_prevista'] as String),
  vencida: json['vencida'] as bool? ?? false,
);

Map<String, dynamic> _$TaskDtoToJson(_TaskDto instance) => <String, dynamic>{
  'tipo': instance.tipo,
  'referencia_id': instance.referenciaId,
  'emprendimiento_id': instance.emprendimientoId,
  'titulo': instance.titulo,
  'detalle': instance.detalle,
  'responsable': instance.responsable,
  'estado': instance.estado,
  'fecha_prevista': instance.fechaPrevista?.toIso8601String(),
  'vencida': instance.vencida,
};
