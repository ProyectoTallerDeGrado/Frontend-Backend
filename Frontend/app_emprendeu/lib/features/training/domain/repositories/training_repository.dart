import '../../../../core/error/result.dart';
import '../entities/training.dart';

abstract interface class TrainingRepository {
  /// Capacitaciones del programa, marcando en las que el emprendedor está inscrito.
  Future<Result<List<Training>>> getTrainings();

  Future<Result<Training>> enroll(int trainingId);
}
