import '../../../../core/error/result.dart';
import '../entities/knowledge_match.dart';
import '../entities/own_document.dart';

/// Archivos propios del emprendedor para la IA local. **Nunca salen del celular.**
abstract interface class OwnDocumentsRepository {
  Future<Result<List<OwnDocument>>> list();

  /// Lee el texto de [chunks] ya troceado, calcula sus vectores y lo guarda.
  /// [onProgress] recibe partes analizadas y total.
  Future<Result<OwnDocument>> add(
    String name,
    List<String> chunks, {
    void Function(int done, int total)? onProgress,
  });

  /// Texto completo del archivo (PDF, DOCX, TXT o MD).
  Future<Result<String>> readText(PickedOwnFile file);

  Future<Result<void>> remove(int id);

  Future<Result<List<KnowledgeMatch>>> search(
    String query, {
    required int limit,
  });
}

/// Elegir un archivo del teléfono. `null` si la persona cancela.
abstract interface class OwnFilePicker {
  Future<PickedOwnFile?> pick(List<String> allowedExtensions);
}
