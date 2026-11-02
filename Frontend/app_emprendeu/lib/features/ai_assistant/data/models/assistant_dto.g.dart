// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessageDto _$ChatMessageDtoFromJson(Map<String, dynamic> json) =>
    _ChatMessageDto(
      mensajeId: (json['mensaje_id'] as num).toInt(),
      tipo: json['tipo'] as String?,
      contenido: json['contenido'] as String,
    );

Map<String, dynamic> _$ChatMessageDtoToJson(_ChatMessageDto instance) =>
    <String, dynamic>{
      'mensaje_id': instance.mensajeId,
      'tipo': instance.tipo,
      'contenido': instance.contenido,
    };

_ConversationSummaryDto _$ConversationSummaryDtoFromJson(
  Map<String, dynamic> json,
) => _ConversationSummaryDto(
  conversacionId: (json['conversacion_id'] as num).toInt(),
  totalMensajes: (json['total_mensajes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ConversationSummaryDtoToJson(
  _ConversationSummaryDto instance,
) => <String, dynamic>{
  'conversacion_id': instance.conversacionId,
  'total_mensajes': instance.totalMensajes,
};

_ChatReplyDto _$ChatReplyDtoFromJson(
  Map<String, dynamic> json,
) => _ChatReplyDto(
  conversacionId: (json['conversacion_id'] as num).toInt(),
  pregunta: ChatMessageDto.fromJson(json['pregunta'] as Map<String, dynamic>),
  respuesta: ChatMessageDto.fromJson(json['respuesta'] as Map<String, dynamic>),
  fuentes:
      (json['fuentes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  derivarMentor: json['derivar_mentor'] as bool? ?? false,
);

Map<String, dynamic> _$ChatReplyDtoToJson(_ChatReplyDto instance) =>
    <String, dynamic>{
      'conversacion_id': instance.conversacionId,
      'pregunta': instance.pregunta,
      'respuesta': instance.respuesta,
      'fuentes': instance.fuentes,
      'derivar_mentor': instance.derivarMentor,
    };
