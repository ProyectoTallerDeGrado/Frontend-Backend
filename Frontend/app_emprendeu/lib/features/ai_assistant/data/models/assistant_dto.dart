import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/coach_conversation.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/entities/coach_reply.dart';

part 'assistant_dto.freezed.dart';
part 'assistant_dto.g.dart';

@freezed
abstract class ChatMessageDto with _$ChatMessageDto {
  const ChatMessageDto._();

  const factory ChatMessageDto({
    @JsonKey(name: 'mensaje_id') required int mensajeId,
    String? tipo,
    required String contenido,
  }) = _ChatMessageDto;

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);

  ChatMessage toEntity({
    List<String> sources = const [],
    bool suggestMentor = false,
  }) => ChatMessage(
    id: mensajeId,
    isUser: tipo == 'usuario',
    text: contenido,
    sources: sources,
    suggestMentor: suggestMentor,
  );
}

@freezed
abstract class ConversationSummaryDto with _$ConversationSummaryDto {
  const ConversationSummaryDto._();

  const factory ConversationSummaryDto({
    @JsonKey(name: 'conversacion_id') required int conversacionId,
    @JsonKey(name: 'total_mensajes') @Default(0) int totalMensajes,
    @JsonKey(name: 'fecha_inicio') DateTime? fechaInicio,
    @JsonKey(name: 'fecha_fin') DateTime? fechaFin,
  }) = _ConversationSummaryDto;

  factory ConversationSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ConversationSummaryDtoFromJson(json);

  ConversationSummary toEntity() => ConversationSummary(
    id: conversacionId,
    messageCount: totalMensajes,
    startedAt: fechaInicio,
    lastMessageAt: fechaFin,
  );
}

@freezed
abstract class ChatReplyDto with _$ChatReplyDto {
  const ChatReplyDto._();

  const factory ChatReplyDto({
    @JsonKey(name: 'conversacion_id') required int conversacionId,
    required ChatMessageDto pregunta,
    required ChatMessageDto respuesta,
    @Default(<String>[]) List<String> fuentes,
    @JsonKey(name: 'derivar_mentor') @Default(false) bool derivarMentor,
  }) = _ChatReplyDto;

  factory ChatReplyDto.fromJson(Map<String, dynamic> json) =>
      _$ChatReplyDtoFromJson(json);

  CoachReply toEntity() => CoachReply(
    conversationId: conversacionId,
    question: pregunta.toEntity(),
    answer: respuesta.toEntity(sources: fuentes, suggestMentor: derivarMentor),
  );
}

CoachConversation conversationFrom(int id, List<ChatMessageDto> messages) =>
    CoachConversation(
      id: id,
      messages: [for (final m in messages) m.toEntity()],
    );
