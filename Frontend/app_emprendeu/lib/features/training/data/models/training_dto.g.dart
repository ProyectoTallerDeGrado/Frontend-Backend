// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrainingDto _$TrainingDtoFromJson(Map<String, dynamic> json) => _TrainingDto(
  capacitacionId: (json['capacitacion_id'] as num).toInt(),
  titulo: json['titulo'] as String,
  descripcion: json['descripcion'] as String?,
  fecha: json['fecha'] == null ? null : DateTime.parse(json['fecha'] as String),
  modalidad: json['modalidad'] as String?,
  tipo: json['tipo'] as String?,
  estado: json['estado'] as String?,
  totalInscritos: (json['total_inscritos'] as num?)?.toInt() ?? 0,
  inscrito: json['inscrito'] as bool? ?? false,
  miAsistencia: json['mi_asistencia'] as bool?,
);

Map<String, dynamic> _$TrainingDtoToJson(_TrainingDto instance) =>
    <String, dynamic>{
      'capacitacion_id': instance.capacitacionId,
      'titulo': instance.titulo,
      'descripcion': instance.descripcion,
      'fecha': instance.fecha?.toIso8601String(),
      'modalidad': instance.modalidad,
      'tipo': instance.tipo,
      'estado': instance.estado,
      'total_inscritos': instance.totalInscritos,
      'inscrito': instance.inscrito,
      'mi_asistencia': instance.miAsistencia,
    };
