import 'chat_message.dart';

/// Respuesta del coach a una pregunta; ambos mensajes ya quedaron guardados.
class CoachReply {
  const CoachReply({
    required this.conversationId,
    required this.question,
    required this.answer,
  });

  final int conversationId;
  final ChatMessage question;
  final ChatMessage answer;
}
