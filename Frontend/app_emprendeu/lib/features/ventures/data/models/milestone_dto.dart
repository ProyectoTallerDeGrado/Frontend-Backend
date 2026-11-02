import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/milestone.dart';

part 'milestone_dto.freezed.dart';
part 'milestone_dto.g.dart';

@freezed
abstract class MilestoneDto with _$MilestoneDto {
  const MilestoneDto._();

  const factory MilestoneDto({
    @JsonKey(name: 'hito_id') required int hitoId,
    required String titulo,
    String? descripcion,
    String? estado,
    @JsonKey(name: 'fecha_estimada') DateTime? fechaEstimada,
    @JsonKey(name: 'fecha_cumplimiento') DateTime? fechaCumplimiento,
  }) = _MilestoneDto;

  factory MilestoneDto.fromJson(Map<String, dynamic> json) =>
      _$MilestoneDtoFromJson(json);

  Milestone toEntity() => Milestone(
    id: hitoId,
    title: titulo,
    description: descripcion,
    done: estado == 'cumplido',
    estimatedAt: fechaEstimada,
    doneAt: fechaCumplimiento,
  );
}
