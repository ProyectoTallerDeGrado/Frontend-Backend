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

_GamificationProfileDto _$GamificationProfileDtoFromJson(
  Map<String, dynamic> json,
) => _GamificationProfileDto(
  xpTotal: (json['xp_total'] as num).toInt(),
  nivel: (json['nivel'] as num).toInt(),
  xpSiguienteNivel: (json['xp_siguiente_nivel'] as num?)?.toInt(),
  xpFaltante: (json['xp_faltante'] as num?)?.toInt(),
  progresoPct: (json['progreso_pct'] as num).toDouble(),
);

Map<String, dynamic> _$GamificationProfileDtoToJson(
  _GamificationProfileDto instance,
) => <String, dynamic>{
  'xp_total': instance.xpTotal,
  'nivel': instance.nivel,
  'xp_siguiente_nivel': instance.xpSiguienteNivel,
  'xp_faltante': instance.xpFaltante,
  'progreso_pct': instance.progresoPct,
};
