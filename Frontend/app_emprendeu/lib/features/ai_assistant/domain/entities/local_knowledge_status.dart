/// Documentos del CIE-U guardados en el celular para la IA local.
class LocalKnowledgeStatus {
  const LocalKnowledgeStatus({
    required this.documents,
    required this.fragments,
    this.syncedAt,
  });

  static const empty = LocalKnowledgeStatus(documents: 0, fragments: 0);

  final int documents;
  final int fragments;

  /// Última sincronización completa con el servidor; `null` si nunca se hizo.
  final DateTime? syncedAt;
}
