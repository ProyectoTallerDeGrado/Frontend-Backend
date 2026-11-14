// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KnowledgeIndexDto _$KnowledgeIndexDtoFromJson(Map<String, dynamic> json) =>
    _KnowledgeIndexDto(
      modeloEmbeddings: json['modelo_embeddings'] as String,
      dimension: (json['dimension'] as num).toInt(),
      documentos:
          (json['documentos'] as List<dynamic>?)
              ?.map((e) => IndexDocumentDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <IndexDocumentDto>[],
    );

Map<String, dynamic> _$KnowledgeIndexDtoToJson(_KnowledgeIndexDto instance) =>
    <String, dynamic>{
      'modelo_embeddings': instance.modeloEmbeddings,
      'dimension': instance.dimension,
      'documentos': instance.documentos,
    };

_IndexDocumentDto _$IndexDocumentDtoFromJson(Map<String, dynamic> json) =>
    _IndexDocumentDto(
      id: (json['documento_conocimiento_id'] as num).toInt(),
      titulo: json['titulo'] as String,
      fuente: json['fuente'] as String?,
      fechaCarga: json['fecha_carga'] == null
          ? null
          : DateTime.parse(json['fecha_carga'] as String),
      totalFragmentos: (json['total_fragmentos'] as num).toInt(),
    );

Map<String, dynamic> _$IndexDocumentDtoToJson(_IndexDocumentDto instance) =>
    <String, dynamic>{
      'documento_conocimiento_id': instance.id,
      'titulo': instance.titulo,
      'fuente': instance.fuente,
      'fecha_carga': instance.fechaCarga?.toIso8601String(),
      'total_fragmentos': instance.totalFragmentos,
    };

_FragmentDto _$FragmentDtoFromJson(Map<String, dynamic> json) => _FragmentDto(
  numeroFragmento: (json['numero_fragmento'] as num?)?.toInt(),
  contenido: json['contenido'] as String,
);

Map<String, dynamic> _$FragmentDtoToJson(_FragmentDto instance) =>
    <String, dynamic>{
      'numero_fragmento': instance.numeroFragmento,
      'contenido': instance.contenido,
    };
