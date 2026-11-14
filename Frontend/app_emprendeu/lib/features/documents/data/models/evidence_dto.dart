import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/evidence.dart';

part 'evidence_dto.freezed.dart';
part 'evidence_dto.g.dart';

@freezed
abstract class EvidenceDto with _$EvidenceDto {
  const EvidenceDto._();

  const factory EvidenceDto({
    @JsonKey(name: 'documento_id') required int documentoId,
    required String nombre,
    String? tipo,
    @JsonKey(name: 'hito_id') int? hitoId,
    @JsonKey(name: 'usuario_id') int? usuarioId,
    @JsonKey(name: 'fecha_subida') DateTime? fechaSubida,
  }) = _EvidenceDto;

  factory EvidenceDto.fromJson(Map<String, dynamic> json) =>
      _$EvidenceDtoFromJson(json);

  Evidence toEntity() => Evidence(
    id: documentoId,
    name: nombre,
    milestoneId: hitoId,
    type: tipo,
    uploadedBy: usuarioId,
    uploadedAt: fechaSubida,
  );
}
