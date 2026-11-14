import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/coach_conversation.dart';
import '../entities/coach_reply.dart';
import '../entities/conversation_summary.dart';
import '../repositories/assistant_repository.dart';

/// Tope del mensaje (lo valida también el servidor).
const maxCoachMessageLength = 2000;

/// Valida una pregunta ya recortada; `null` si es válida. La usan el coach en
/// línea y el del celular.
FieldFailure? coachMessageError(String text) {
  if (text.isEmpty) {
    return const FieldFailure('message', 'Escribe tu pregunta.');
  }
  if (text.length > maxCoachMessageLength) {
    return const FieldFailure(
      'message',
      'Tu mensaje es muy largo (máximo $maxCoachMessageLength caracteres).',
    );
  }
  return null;
}

class GetLatestConversationUseCase {
  const GetLatestConversationUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Result<CoachConversation?>> call() =>
      _repository.getLatestConversation();
}

/// Conversaciones anteriores del emprendedor con el coach (CU11).
class ListConversationsUseCase {
  const ListConversationsUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Result<List<ConversationSummary>>> call() =>
      _repository.getConversations();
}

/// Reabre una conversación anterior con todos sus mensajes.
class OpenConversationUseCase {
  const OpenConversationUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Result<CoachConversation>> call(int id) =>
      _repository.getConversation(id);
}

class AskCoachUseCase {
  const AskCoachUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Result<CoachReply>> call(
    String message, {
    int? conversationId,
    int? ventureId,
  }) async {
    final text = message.trim();
    final invalid = coachMessageError(text);
    if (invalid != null) return Result.err(invalid);
    return _repository.ask(
      text,
      conversationId: conversationId,
      ventureId: ventureId,
    );
  }
}
