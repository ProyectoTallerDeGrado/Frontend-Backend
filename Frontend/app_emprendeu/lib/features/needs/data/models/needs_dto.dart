import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/venture_need.dart';

part 'needs_dto.freezed.dart';
part 'needs_dto.g.dart';

@freezed
abstract class NeedCategoryDto with _$NeedCategoryDto {
  const NeedCategoryDto._();

  const factory NeedCategoryDto({
    @JsonKey(name: 'necesidad_id') required int necesidadId,
    required String nombre,
    String? descripcion,
  }) = _NeedCategoryDto;

  factory NeedCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$NeedCategoryDtoFromJson(json);

  NeedCategory toEntity() =>
      NeedCategory(id: necesidadId, name: nombre, description: descripcion);
}

@freezed
abstract class VentureNeedDto with _$VentureNeedDto {
  const VentureNeedDto._();

  const factory VentureNeedDto({
    @JsonKey(name: 'emprendimiento_necesidad_id') required int id,
    @JsonKey(name: 'necesidad_id') required int necesidadId,
    required String necesidad,
    String? estado,
    String? prioridad,
    @Default('necesidad') String tipo,
    String? descripcion,
    @JsonKey(name: 'fecha_detectada') DateTime? fechaDetectada,
    @JsonKey(name: 'fecha_resuelta') DateTime? fechaResuelta,
  }) = _VentureNeedDto;

  factory VentureNeedDto.fromJson(Map<String, dynamic> json) =>
      _$VentureNeedDtoFromJson(json);

  VentureNeed toEntity() => VentureNeed(
    id: id,
    categoryId: necesidadId,
    categoryName: necesidad,
    kind: tipo == 'dificultad' ? NeedKind.difficulty : NeedKind.need,
    priority: switch (prioridad) {
      'alta' => NeedPriority.high,
      'baja' => NeedPriority.low,
      _ => NeedPriority.medium,
    },
    resolved: estado == 'resuelta',
    description: descripcion,
    detectedAt: fechaDetectada,
    resolvedAt: fechaResuelta,
  );
}
