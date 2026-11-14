import 'package:freezed_annotation/freezed_annotation.dart';

part 'knowledge_dto.freezed.dart';
part 'knowledge_dto.g.dart';

/// `GET /ai/knowledge/index`: manifiesto de la base activa del CIE-U.
@freezed
abstract class KnowledgeIndexDto with _$KnowledgeIndexDto {
  const factory KnowledgeIndexDto({
    @JsonKey(name: 'modelo_embeddings') required String modeloEmbeddings,
    required int dimension,
    @Default(<IndexDocumentDto>[]) List<IndexDocumentDto> documentos,
  }) = _KnowledgeIndexDto;

  factory KnowledgeIndexDto.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeIndexDtoFromJson(json);
}

@freezed
abstract class IndexDocumentDto with _$IndexDocumentDto {
  const factory IndexDocumentDto({
    @JsonKey(name: 'documento_conocimiento_id') required int id,
    required String titulo,
    String? fuente,
    @JsonKey(name: 'fecha_carga') DateTime? fechaCarga,
    @JsonKey(name: 'total_fragmentos') required int totalFragmentos,
  }) = _IndexDocumentDto;

  factory IndexDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$IndexDocumentDtoFromJson(json);
}

/// Un fragmento de `GET /ai/knowledge/{id}/fragments?incluir_embedding=false`.
@freezed
abstract class FragmentDto with _$FragmentDto {
  const factory FragmentDto({
    @JsonKey(name: 'numero_fragmento') int? numeroFragmento,
    required String contenido,
  }) = _FragmentDto;

  factory FragmentDto.fromJson(Map<String, dynamic> json) =>
      _$FragmentDtoFromJson(json);
}
