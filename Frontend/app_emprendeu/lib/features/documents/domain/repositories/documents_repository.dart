import '../../../../core/error/result.dart';
import '../entities/downloaded_document.dart';
import '../entities/evidence.dart';
import '../entities/picked_file.dart';

abstract interface class DocumentsRepository {
  /// Sube [file] al emprendimiento; con [milestoneId] queda como evidencia del hito.
  Future<Result<Evidence>> upload({
    required int ventureId,
    int? milestoneId,
    required PickedFile file,
  });

  /// Archivos del emprendimiento (incluida la evidencia de sus hitos).
  Future<Result<List<Evidence>>> listForVenture(int ventureId);

  /// Elimina un archivo propio (CU30); el servidor lo registra en auditoría.
  Future<Result<void>> delete(int documentId);

  /// Descarga [document] al celular (CU30). Si ya se bajó antes, reutiliza la copia.
  Future<Result<DownloadedDocument>> download(Evidence document);
}
