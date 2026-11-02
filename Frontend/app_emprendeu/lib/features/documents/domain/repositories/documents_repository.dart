import '../../../../core/error/result.dart';
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
}
