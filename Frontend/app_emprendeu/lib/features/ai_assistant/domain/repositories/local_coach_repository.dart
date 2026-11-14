import '../../../../core/error/result.dart';
import '../entities/chat_message.dart';

/// Modelo de lenguaje del celular y la conversación que se guarda en el dispositivo.
abstract interface class LocalCoachRepository {
  /// Redacta la respuesta. [onPartial] recibe el texto acumulado mientras se genera.
  Future<Result<String>> generate({
    required String system,
    required String prompt,
    required void Function(String partial) onPartial,
  });

  /// Conversación local guardada (vacía si no hay).
  Future<Result<List<ChatMessage>>> loadConversation();

  Future<Result<void>> saveConversation(List<ChatMessage> messages);

  Future<Result<void>> clearConversation();
}
