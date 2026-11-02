import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/history_event.dart';

part 'history_dto.freezed.dart';
part 'history_dto.g.dart';

@freezed
abstract class HistoryEventDto with _$HistoryEventDto {
  const HistoryEventDto._();

  const factory HistoryEventDto({
    required String tipo,
    @JsonKey(name: 'referencia_id') required int referenciaId,
    DateTime? fecha,
    required String titulo,
    String? detalle,
    String? estado,
    String? autor,
  }) = _HistoryEventDto;

  factory HistoryEventDto.fromJson(Map<String, dynamic> json) =>
      _$HistoryEventDtoFromJson(json);

  HistoryEvent toEntity() => HistoryEvent(
    kind: switch (tipo) {
      'sesion' => HistoryKind.session,
      'avance' => HistoryKind.progress,
      'hito' => HistoryKind.milestone,
      'recomendacion' => HistoryKind.recommendation,
      'compromiso' => HistoryKind.commitment,
      _ => HistoryKind.stage,
    },
    refId: referenciaId,
    date: fecha,
    title: titulo,
    detail: detalle,
    state: estado,
    author: autor,
  );
}
