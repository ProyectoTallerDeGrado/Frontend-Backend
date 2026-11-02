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
abstract class BadgeProgressDto with _$BadgeProgressDto {
  const BadgeProgressDto._();

  const factory BadgeProgressDto({
    @JsonKey(name: 'insignia_id') required int insigniaId,
    required String nombre,
    String? criterio,
    @JsonKey(name: 'xp_recompensa') @Default(0) int xpRecompensa,
    @Default(false) bool obtenida,
    @JsonKey(name: 'fecha_obtenida') DateTime? fechaObtenida,
  }) = _BadgeProgressDto;

  factory BadgeProgressDto.fromJson(Map<String, dynamic> json) =>
      _$BadgeProgressDtoFromJson(json);

  BadgeProgress toEntity() => BadgeProgress(
    id: insigniaId,
    name: nombre,
    criterion: criterio,
    xpReward: xpRecompensa,
    earned: obtenida,
    earnedAt: fechaObtenida,
  );
}

@freezed
abstract class XpMovementDto with _$XpMovementDto {
  const XpMovementDto._();

  const factory XpMovementDto({
    String? motivo,
    required int cantidad,
    DateTime? fecha,
  }) = _XpMovementDto;

  factory XpMovementDto.fromJson(Map<String, dynamic> json) =>
      _$XpMovementDtoFromJson(json);

  XpMovement toEntity() =>
      XpMovement(reason: motivo, amount: cantidad, date: fecha);
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
    @Default(<BadgeProgressDto>[]) List<BadgeProgressDto> insignias,
    @Default(<XpMovementDto>[]) List<XpMovementDto> historial,
  }) = _GamificationProfileDto;

  factory GamificationProfileDto.fromJson(Map<String, dynamic> json) =>
      _$GamificationProfileDtoFromJson(json);

  GamificationProfile toEntity() => GamificationProfile(
    xp: xpTotal,
    level: nivel,
    nextLevelXp: xpSiguienteNivel,
    missingXp: xpFaltante,
    progressPct: progresoPct,
    badges: [for (final b in insignias) b.toEntity()],
    history: [for (final h in historial) h.toEntity()],
  );
}
