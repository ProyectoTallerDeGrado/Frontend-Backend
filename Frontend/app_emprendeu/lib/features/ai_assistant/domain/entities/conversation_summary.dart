/// Una conversación guardada con el coach, para elegir cuál reabrir (CU11).
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.messageCount,
    this.startedAt,
    this.lastMessageAt,
  });

  final int id;
  final int messageCount;
  final DateTime? startedAt;

  /// Cuándo se escribió por última vez en ella.
  final DateTime? lastMessageAt;

  DateTime? get when => lastMessageAt ?? startedAt;
}
