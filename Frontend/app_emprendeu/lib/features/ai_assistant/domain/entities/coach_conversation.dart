import 'chat_message.dart';

/// Conversación guardada con el coach.
class CoachConversation {
  const CoachConversation({required this.id, required this.messages});

  final int id;
  final List<ChatMessage> messages;
}
