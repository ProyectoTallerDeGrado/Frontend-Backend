import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/venture.dart';

part 'venture_dto.freezed.dart';
part 'venture_dto.g.dart';

@freezed
abstract class StageDto with _$StageDto {
  const factory StageDto({required String nombre}) = _StageDto;

  factory StageDto.fromJson(Map<String, dynamic> json) =>
      _$StageDtoFromJson(json);
}

/// Emprendimiento tal como lo entrega `/ventures`.
@freezed
abstract class VentureDto with _$VentureDto {
  const VentureDto._();

  const factory VentureDto({
    @JsonKey(name: 'emprendimiento_id') required int emprendimientoId,
    required String nombre,
    @JsonKey(name: 'etapa_actual') StageDto? etapaActual,
    String? descripcion,
    String? sector,
    String? estado,
  }) = _VentureDto;

  factory VentureDto.fromJson(Map<String, dynamic> json) =>
      _$VentureDtoFromJson(json);

  Venture toEntity() => Venture(
    id: emprendimientoId,
    name: nombre,
    stageName: etapaActual?.nombre,
    description: descripcion,
    sector: sector,
    status: estado,
  );
}
