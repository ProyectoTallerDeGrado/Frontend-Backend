// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompletionDto _$CompletionDtoFromJson(Map<String, dynamic> json) =>
    _CompletionDto(
      retoId: (json['reto_id'] as num).toInt(),
      xpOtorgado: (json['xp_otorgado'] as num).toInt(),
      xpTotal: (json['xp_total'] as num).toInt(),
      nivel: (json['nivel'] as num).toInt(),
      subioDeNivel: json['subio_de_nivel'] as bool,
      insigniasNuevas:
          (json['insignias_nuevas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$CompletionDtoToJson(_CompletionDto instance) =>
    <String, dynamic>{
      'reto_id': instance.retoId,
      'xp_otorgado': instance.xpOtorgado,
      'xp_total': instance.xpTotal,
      'nivel': instance.nivel,
      'subio_de_nivel': instance.subioDeNivel,
      'insignias_nuevas': instance.insigniasNuevas,
    };

_BadgeProgressDto _$BadgeProgressDtoFromJson(Map<String, dynamic> json) =>
    _BadgeProgressDto(
      insigniaId: (json['insignia_id'] as num).toInt(),
      nombre: json['nombre'] as String,
      criterio: json['criterio'] as String?,
      xpRecompensa: (json['xp_recompensa'] as num?)?.toInt() ?? 0,
      obtenida: json['obtenida'] as bool? ?? false,
      fechaObtenida: json['fecha_obtenida'] == null
          ? null
          : DateTime.parse(json['fecha_obtenida'] as String),
    );

Map<String, dynamic> _$BadgeProgressDtoToJson(_BadgeProgressDto instance) =>
    <String, dynamic>{
      'insignia_id': instance.insigniaId,
      'nombre': instance.nombre,
      'criterio': instance.criterio,
      'xp_recompensa': instance.xpRecompensa,
      'obtenida': instance.obtenida,
      'fecha_obtenida': instance.fechaObtenida?.toIso8601String(),
    };

_XpMovementDto _$XpMovementDtoFromJson(Map<String, dynamic> json) =>
    _XpMovementDto(
      motivo: json['motivo'] as String?,
      cantidad: (json['cantidad'] as num).toInt(),
      fecha: json['fecha'] == null
          ? null
          : DateTime.parse(json['fecha'] as String),
    );

Map<String, dynamic> _$XpMovementDtoToJson(_XpMovementDto instance) =>
    <String, dynamic>{
      'motivo': instance.motivo,
      'cantidad': instance.cantidad,
      'fecha': instance.fecha?.toIso8601String(),
    };

_GamificationProfileDto _$GamificationProfileDtoFromJson(
  Map<String, dynamic> json,
) => _GamificationProfileDto(
  xpTotal: (json['xp_total'] as num).toInt(),
  nivel: (json['nivel'] as num).toInt(),
  xpSiguienteNivel: (json['xp_siguiente_nivel'] as num?)?.toInt(),
  xpFaltante: (json['xp_faltante'] as num?)?.toInt(),
  progresoPct: (json['progreso_pct'] as num).toDouble(),
  insignias:
      (json['insignias'] as List<dynamic>?)
          ?.map((e) => BadgeProgressDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BadgeProgressDto>[],
  historial:
      (json['historial'] as List<dynamic>?)
          ?.map((e) => XpMovementDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <XpMovementDto>[],
);

Map<String, dynamic> _$GamificationProfileDtoToJson(
  _GamificationProfileDto instance,
) => <String, dynamic>{
  'xp_total': instance.xpTotal,
  'nivel': instance.nivel,
  'xp_siguiente_nivel': instance.xpSiguienteNivel,
  'xp_faltante': instance.xpFaltante,
  'progreso_pct': instance.progresoPct,
  'insignias': instance.insignias,
  'historial': instance.historial,
};
