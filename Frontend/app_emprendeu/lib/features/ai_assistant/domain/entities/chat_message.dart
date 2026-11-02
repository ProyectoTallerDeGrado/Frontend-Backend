/// Un mensaje de la conversación con el coach.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.sources = const [],
    this.suggestMentor = false,
  });

  /// Identificador del servidor (`-1` mientras el mensaje aún se está enviando).
  final int id;
  final bool isUser;
  final String text;

  /// Documentos de la base del CIE-U en los que se apoya la respuesta.
  final List<String> sources;

  /// El coach recomienda hablar con una persona (sin fuente, o tema legal/financiero).
  final bool suggestMentor;
}
