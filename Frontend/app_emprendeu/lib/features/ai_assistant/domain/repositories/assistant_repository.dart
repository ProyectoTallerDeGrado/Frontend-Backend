import '../../../../core/error/result.dart';
import '../entities/coach_conversation.dart';
import '../entities/coach_reply.dart';
import '../entities/conversation_summary.dart';

/// Conversar con el coach IA (requiere conexión).
abstract interface class AssistantRepository {
  /// La conversación más reciente del emprendedor, o `null` si nunca habló con el coach.
  Future<Result<CoachConversation?>> getLatestConversation();

  /// Todas las conversaciones del emprendedor, de la más reciente a la más antigua.
  Future<Result<List<ConversationSummary>>> getConversations();

  /// Una conversación con todos sus mensajes.
  Future<Result<CoachConversation>> getConversation(int id);

  /// Envía [message]; sin [conversationId] abre una conversación nueva, asociada
  /// a [ventureId] (sin indicarlo, al primer emprendimiento del usuario).
  Future<Result<CoachReply>> ask(
    String message, {
    int? conversationId,
    int? ventureId,
  });
}
