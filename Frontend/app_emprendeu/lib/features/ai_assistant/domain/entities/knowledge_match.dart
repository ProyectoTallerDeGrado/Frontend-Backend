/// Fragmento de un documento que se parece a la pregunta (resultado de la búsqueda).
class KnowledgeMatch {
  const KnowledgeMatch({
    required this.text,
    required this.documentId,
    required this.title,
    required this.score,
    this.own = false,
  });

  final String text;
  final int documentId;
  final String title;

  /// Es un archivo del propio emprendedor (no un documento del CIE-U).
  final bool own;

  /// Similitud coseno con la pregunta (1 = idéntico).
  final double score;
}
