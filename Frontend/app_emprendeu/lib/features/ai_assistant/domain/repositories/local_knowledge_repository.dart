import '../../../../core/error/result.dart';
import '../entities/knowledge_match.dart';
import '../entities/local_knowledge_status.dart';

/// Base de conocimiento del CIE-U copiada en el celular (RAG local).
abstract interface class LocalKnowledgeRepository {
  Future<Result<LocalKnowledgeStatus>> status();

  /// Trae del servidor los documentos nuevos y borra los retirados. Los vectores
  /// se calculan en el celular. [onProgress] recibe documentos hechos y total.
  Future<Result<LocalKnowledgeStatus>> sync({
    void Function(int done, int total)? onProgress,
  });

  /// Los [limit] fragmentos más parecidos a [query], del más al menos parecido.
  Future<Result<List<KnowledgeMatch>>> search(
    String query, {
    required int limit,
  });
}
