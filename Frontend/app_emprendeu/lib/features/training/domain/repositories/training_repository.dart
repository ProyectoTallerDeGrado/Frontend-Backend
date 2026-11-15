import '../../../../core/error/result.dart';
import '../entities/training.dart';

abstract interface class TrainingRepository {
  /// Una página de capacitaciones del programa, marcando en las que el
  /// emprendedor está inscrito. La primera incluye también las suyas que no
  /// salen en la lista general (p. ej. ya realizadas).
  Future<Result<TrainingPage>> getTrainings({int page = 1});

  Future<Result<Training>> enroll(int trainingId);
}
