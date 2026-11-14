import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/task.dart';

part 'task_dto.freezed.dart';
part 'task_dto.g.dart';

@freezed
abstract class TaskDto with _$TaskDto {
  const TaskDto._();

  const factory TaskDto({
    required String tipo,
    @JsonKey(name: 'referencia_id') required int referenciaId,
    @JsonKey(name: 'emprendimiento_id') required int emprendimientoId,
    required String titulo,
    String? detalle,
    String? responsable,
    required String estado,
    @JsonKey(name: 'fecha_prevista') DateTime? fechaPrevista,
    @Default(false) bool vencida,
  }) = _TaskDto;

  factory TaskDto.fromJson(Map<String, dynamic> json) =>
      _$TaskDtoFromJson(json);

  Task toEntity() => Task(
    kind: tipo == 'hito' ? TaskKind.milestone : TaskKind.commitment,
    refId: referenciaId,
    ventureId: emprendimientoId,
    title: titulo,
    detail: detalle,
    responsible: responsable,
    state: estado == 'cumplido' ? TaskState.done : TaskState.pending,
    dueAt: fechaPrevista,
    overdue: vencida,
  );
}
