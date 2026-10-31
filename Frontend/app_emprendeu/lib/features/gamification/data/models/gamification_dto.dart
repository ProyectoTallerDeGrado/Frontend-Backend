import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/completion_result.dart';
import '../../domain/entities/gamification_profile.dart';

part 'gamification_dto.freezed.dart';
part 'gamification_dto.g.dart';

@freezed
abstract class CompletionDto with _$CompletionDto {
  const CompletionDto._();

  const factory CompletionDto({
    @JsonKey(name: 'reto_id') required int retoId,
    @JsonKey(name: 'xp_otorgado') required int xpOtorgado,
    @JsonKey(name: 'xp_total') required int xpTotal,
    required int nivel,
    @JsonKey(name: 'subio_de_nivel') required bool subioDeNivel,
    @JsonKey(name: 'insignias_nuevas')
    @Default(<String>[])
    List<String> insigniasNuevas,
  }) = _CompletionDto;

  factory CompletionDto.fromJson(Map<String, dynamic> json) =>
      _$CompletionDtoFromJson(json);

  CompletionResult toEntity() => CompletionResult(
    challengeId: retoId,
    xpAwarded: xpOtorgado,
    xpTotal: xpTotal,
    level: nivel,
    leveledUp: subioDeNivel,
    newBadges: insigniasNuevas,
  );
}

@freezed
abstract class GamificationProfileDto with _$GamificationProfileDto {
  const GamificationProfileDto._();

  const factory GamificationProfileDto({
    @JsonKey(name: 'xp_total') required int xpTotal,
    required int nivel,
    @JsonKey(name: 'xp_siguiente_nivel') int? xpSiguienteNivel,
    @JsonKey(name: 'xp_faltante') int? xpFaltante,
    @JsonKey(name: 'progreso_pct') required double progresoPct,
  }) = _GamificationProfileDto;

  factory GamificationProfileDto.fromJson(Map<String, dynamic> json) =>
      _$GamificationProfileDtoFromJson(json);

  GamificationProfile toEntity() => GamificationProfile(
    xp: xpTotal,
    level: nivel,
    nextLevelXp: xpSiguienteNivel,
    missingXp: xpFaltante,
    progressPct: progresoPct,
  );
}
