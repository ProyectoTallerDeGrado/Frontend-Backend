// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JourneyStageDto _$JourneyStageDtoFromJson(Map<String, dynamic> json) =>
    _JourneyStageDto(
      etapaId: (json['etapa_id'] as num).toInt(),
      nombre: json['nombre'] as String,
      estado: json['estado'] as String,
    );

Map<String, dynamic> _$JourneyStageDtoToJson(_JourneyStageDto instance) =>
    <String, dynamic>{
      'etapa_id': instance.etapaId,
      'nombre': instance.nombre,
      'estado': instance.estado,
    };

_JourneyChallengeDto _$JourneyChallengeDtoFromJson(Map<String, dynamic> json) =>
    _JourneyChallengeDto(
      retoId: (json['reto_id'] as num).toInt(),
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      etapa: json['etapa'] as String?,
      xpRecompensa: (json['xp_recompensa'] as num).toInt(),
      estado: json['estado'] as String,
      fechaCompletado: json['fecha_completado'] == null
          ? null
          : DateTime.parse(json['fecha_completado'] as String),
      criterioCompletado: json['criterio_completado'] as String?,
      requiereEvidencia: json['requiere_evidencia'] as bool? ?? false,
    );

Map<String, dynamic> _$JourneyChallengeDtoToJson(
  _JourneyChallengeDto instance,
) => <String, dynamic>{
  'reto_id': instance.retoId,
  'titulo': instance.titulo,
  'descripcion': instance.descripcion,
  'etapa': instance.etapa,
  'xp_recompensa': instance.xpRecompensa,
  'estado': instance.estado,
  'fecha_completado': instance.fechaCompletado?.toIso8601String(),
  'criterio_completado': instance.criterioCompletado,
  'requiere_evidencia': instance.requiereEvidencia,
};

_JourneyDto _$JourneyDtoFromJson(Map<String, dynamic> json) => _JourneyDto(
  emprendimientoId: (json['emprendimiento_id'] as num).toInt(),
  xpTotal: (json['xp_total'] as num).toInt(),
  nivel: (json['nivel'] as num).toInt(),
  etapas: (json['etapas'] as List<dynamic>)
      .map((e) => JourneyStageDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  retos: (json['retos'] as List<dynamic>)
      .map((e) => JourneyChallengeDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$JourneyDtoToJson(_JourneyDto instance) =>
    <String, dynamic>{
      'emprendimiento_id': instance.emprendimientoId,
      'xp_total': instance.xpTotal,
      'nivel': instance.nivel,
      'etapas': instance.etapas,
      'retos': instance.retos,
    };
