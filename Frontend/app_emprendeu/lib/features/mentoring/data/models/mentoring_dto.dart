import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/commitment.dart';
import '../../domain/entities/progress_log.dart';

part 'mentoring_dto.freezed.dart';
part 'mentoring_dto.g.dart';

@freezed
abstract class CommitmentDto with _$CommitmentDto {
  const CommitmentDto._();

  const factory CommitmentDto({
    @JsonKey(name: 'compromiso_id') required int compromisoId,
    // Un compromiso puede registrarse sin sesion (el backend lo admite).
    @JsonKey(name: 'sesion_id') int? sesionId,
    String? descripcion,
    String? estado,
    @JsonKey(name: 'fecha_limite') DateTime? fechaLimite,
  }) = _CommitmentDto;

  factory CommitmentDto.fromJson(Map<String, dynamic> json) =>
      _$CommitmentDtoFromJson(json);

  Commitment toEntity() => Commitment(
    id: compromisoId,
    sessionId: sesionId,
    description: descripcion ?? '',
    done: estado == 'cumplido',
    dueDate: fechaLimite?.toLocal(),
  );
}

@freezed
abstract class ProgressDto with _$ProgressDto {
  const ProgressDto._();

  const factory ProgressDto({
    @JsonKey(name: 'seguimiento_id') required int seguimientoId,
    String? observaciones,
    DateTime? fecha,
    @JsonKey(name: 'referencia_cliente') String? referenciaCliente,
  }) = _ProgressDto;

  factory ProgressDto.fromJson(Map<String, dynamic> json) =>
      _$ProgressDtoFromJson(json);

  ProgressLog toEntity() => ProgressLog(
    id: seguimientoId,
    clientRef: referenciaCliente,
    text: observaciones ?? '',
    createdAt: (fecha ?? DateTime.now()).toLocal(),
  );
}

@freezed
abstract class SyncResultDto with _$SyncResultDto {
  const factory SyncResultDto({
    @Default(<ProgressDto>[]) List<ProgressDto> avances,
    @Default(<CommitmentDto>[]) List<CommitmentDto> compromisos,
    @Default(<String>[]) List<String> errores,
  }) = _SyncResultDto;

  factory SyncResultDto.fromJson(Map<String, dynamic> json) =>
      _$SyncResultDtoFromJson(json);
}
