import '../../../../core/error/result.dart';
import '../entities/training.dart';

abstract interface class TrainingRepository {
  /// Capacitaciones publicadas (y ya realizadas) con la asistencia propia.
  Future<Result<List<Training>>> getPublished();

  Future<Result<void>> enroll(int trainingId);
}
