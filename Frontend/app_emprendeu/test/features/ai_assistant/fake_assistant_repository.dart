import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/coach_conversation.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/coach_reply.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/conversation_summary.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/repositories/assistant_repository.dart';

/// Coach en memoria. [failure] simula que el servicio de IA no responde.
class FakeAssistantRepository implements AssistantRepository {
  FakeAssistantRepository({
    this.conversation,
    this.answer = 'Separa costos fijos y variables.',
    this.sources = const ['Guía de costos'],
    this.suggestMentor = false,
    this.failure,
  });

  CoachConversation? conversation;
  String answer;
  List<String> sources;
  bool suggestMentor;
  Failure? failure;

  int askCalls = 0;
  String? lastMessage;
  int? lastConversationId;
  int? lastVentureId;

  /// Conversaciones guardadas (la primera es la más reciente) y sus mensajes por id.
  List<ConversationSummary> summaries = [];
  Map<int, CoachConversation> byId = {};
  int? lastOpenedId;

  @override
  Future<Result<CoachConversation?>> getLatestConversation() async =>
      Result.ok(conversation);

  @override
  Future<Result<List<ConversationSummary>>> getConversations() async =>
      failure != null ? Result.err(failure!) : Result.ok(summaries);

  @override
  Future<Result<CoachConversation>> getConversation(int id) async {
    lastOpenedId = id;
    final found = byId[id];
    return found == null
        ? const Result.err(UnknownFailure('Conversación no encontrada.'))
        : Result.ok(found);
  }

  @override
  Future<Result<CoachReply>> ask(
    String message, {
    int? conversationId,
    int? ventureId,
  }) async {
    askCalls++;
    lastMessage = message;
    lastConversationId = conversationId;
    lastVentureId = ventureId;
    if (failure != null) return Result.err(failure!);
    final id = conversationId ?? 77;
    return Result.ok(
      CoachReply(
        conversationId: id,
        question: ChatMessage(id: askCalls * 10, isUser: true, text: message),
        answer: ChatMessage(
          id: askCalls * 10 + 1,
          isUser: false,
          text: answer,
          sources: sources,
          suggestMentor: suggestMentor,
        ),
      ),
    );
  }
}
