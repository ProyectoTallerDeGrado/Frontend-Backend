import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/training.dart';

part 'training_dto.freezed.dart';
part 'training_dto.g.dart';

@freezed
abstract class TrainingDto with _$TrainingDto {
  const TrainingDto._();

  const factory TrainingDto({
    @JsonKey(name: 'capacitacion_id') required int capacitacionId,
    required String titulo,
    String? descripcion,
    DateTime? fecha,
    String? modalidad,
    String? tipo,
    String? estado,
    @JsonKey(name: 'total_inscritos') @Default(0) int totalInscritos,
    @Default(false) bool? inscrito,
    @JsonKey(name: 'mi_asistencia') bool? miAsistencia,
  }) = _TrainingDto;

  factory TrainingDto.fromJson(Map<String, dynamic> json) =>
      _$TrainingDtoFromJson(json);

  Training toEntity() => Training(
    id: capacitacionId,
    title: titulo,
    description: descripcion,
    date: fecha,
    modality: modalidad,
    type: tipo,
    state: estado ?? 'publicada',
    enrolledCount: totalInscritos,
    enrolled: inscrito ?? false,
    attended: miAsistencia,
  );
}
