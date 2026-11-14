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
    bool? inscrito,
    bool? asistencia,
  }) = _TrainingDto;

  factory TrainingDto.fromJson(Map<String, dynamic> json) =>
      _$TrainingDtoFromJson(json);

  Training toEntity({bool? enrolled}) => Training(
    id: capacitacionId,
    title: titulo,
    status: estado ?? 'programada',
    description: descripcion,
    date: fecha,
    modality: modalidad,
    kind: tipo,
    enrolled: enrolled ?? inscrito ?? false,
    attended: asistencia,
  );
}
