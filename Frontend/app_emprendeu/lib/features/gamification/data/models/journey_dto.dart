import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/journey.dart';

part 'journey_dto.freezed.dart';
part 'journey_dto.g.dart';

@freezed
abstract class JourneyStageDto with _$JourneyStageDto {
  const factory JourneyStageDto({
    @JsonKey(name: 'etapa_id') required int etapaId,
    required String nombre,
    required String estado,
  }) = _JourneyStageDto;

  factory JourneyStageDto.fromJson(Map<String, dynamic> json) =>
      _$JourneyStageDtoFromJson(json);
}

@freezed
abstract class JourneyChallengeDto with _$JourneyChallengeDto {
  const factory JourneyChallengeDto({
    @JsonKey(name: 'reto_id') required int retoId,
    required String titulo,
    String? descripcion,
    String? etapa,
    @JsonKey(name: 'xp_recompensa') required int xpRecompensa,
    required String estado,
    @JsonKey(name: 'fecha_completado') DateTime? fechaCompletado,
    @JsonKey(name: 'criterio_completado') String? criterioCompletado,
    @JsonKey(name: 'requiere_evidencia') @Default(false) bool requiereEvidencia,
  }) = _JourneyChallengeDto;

  factory JourneyChallengeDto.fromJson(Map<String, dynamic> json) =>
      _$JourneyChallengeDtoFromJson(json);
}

@freezed
abstract class JourneyDto with _$JourneyDto {
  const JourneyDto._();

  const factory JourneyDto({
    @JsonKey(name: 'emprendimiento_id') required int emprendimientoId,
    @JsonKey(name: 'xp_total') required int xpTotal,
    required int nivel,
    required List<JourneyStageDto> etapas,
    required List<JourneyChallengeDto> retos,
  }) = _JourneyDto;

  factory JourneyDto.fromJson(Map<String, dynamic> json) =>
      _$JourneyDtoFromJson(json);

  Journey toEntity() => Journey(
    ventureId: emprendimientoId,
    xp: xpTotal,
    level: nivel,
    stages: [
      for (final e in etapas)
        JourneyStage(
          id: e.etapaId,
          name: e.nombre,
          status: switch (e.estado) {
            'cumplida' => StageStatus.done,
            'en_curso' => StageStatus.current,
            _ => StageStatus.locked,
          },
        ),
    ],
    challenges: [
      for (final r in retos)
        JourneyChallenge(
          id: r.retoId,
          title: r.titulo,
          description: r.descripcion,
          stageName: r.etapa,
          xp: r.xpRecompensa,
          completedAt: r.fechaCompletado,
          criterion: r.criterioCompletado,
          requiresEvidence: r.requiereEvidencia,
          status: switch (r.estado) {
            'cumplido' => ChallengeStatus.done,
            'en_curso' => ChallengeStatus.current,
            _ => ChallengeStatus.locked,
          },
        ),
    ],
  );
}
