/// Lo que la base de conocimiento local necesita del modelo de embeddings.
/// Lo implementa `LocalAiEngineDataSource`; en pruebas, un doble.
abstract interface class TextEmbedder {
  /// Identidad del modelo (si cambia, hay que recalcular los vectores).
  String get embedderId;

  Future<List<List<double>>> embedDocuments(List<String> texts);

  Future<List<double>> embedQuery(String text);
}
