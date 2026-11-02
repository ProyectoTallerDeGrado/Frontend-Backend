import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/venture_need.dart';

part 'need_dto.freezed.dart';
part 'need_dto.g.dart';

@freezed
abstract class VentureNeedDto with _$VentureNeedDto {
  const VentureNeedDto._();

  const factory VentureNeedDto({
    @JsonKey(name: 'emprendimiento_necesidad_id') required int id,
    required String necesidad,
    String? estado,
    String? prioridad,
    @JsonKey(name: 'fecha_detectada') DateTime? fechaDetectada,
    @JsonKey(name: 'fecha_resuelta') DateTime? fechaResuelta,
  }) = _VentureNeedDto;

  factory VentureNeedDto.fromJson(Map<String, dynamic> json) =>
      _$VentureNeedDtoFromJson(json);

  VentureNeed toEntity() => VentureNeed(
    id: id,
    name: necesidad,
    resolved: estado == 'resuelta',
    priority: prioridad ?? 'media',
    detectedAt: fechaDetectada,
    resolvedAt: fechaResuelta,
  );
}

@freezed
abstract class NeedCatalogDto with _$NeedCatalogDto {
  const factory NeedCatalogDto({required String nombre}) = _NeedCatalogDto;

  factory NeedCatalogDto.fromJson(Map<String, dynamic> json) =>
      _$NeedCatalogDtoFromJson(json);
}
