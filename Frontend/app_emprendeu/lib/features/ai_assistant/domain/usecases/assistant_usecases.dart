import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/coach_conversation.dart';
import '../entities/coach_reply.dart';
import '../repositories/assistant_repository.dart';

/// Tope del mensaje (lo valida también el servidor).
const maxCoachMessageLength = 2000;

class GetLatestConversationUseCase {
  const GetLatestConversationUseCase(this._repository);
  final AssistantRepository _repository;

  Future<Result<CoachConversation?>> call() =>
      _repository.getLatestConversation();
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
    if (text.isEmpty) {
      return const Result.err(FieldFailure('message', 'Escribe tu pregunta.'));
    }
    if (text.length > maxCoachMessageLength) {
      return const Result.err(
        FieldFailure(
          'message',
          'Tu mensaje es muy largo (máximo $maxCoachMessageLength caracteres).',
        ),
      );
    }
    return _repository.ask(
      text,
      conversationId: conversationId,
      ventureId: ventureId,
    );
  }
}
