import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/milestone.dart';
import '../repositories/ventures_repository.dart';

class GetMilestonesUseCase {
  const GetMilestonesUseCase(this._repository);
  final VenturesRepository _repository;

  Future<Result<List<Milestone>>> call(int ventureId) =>
      _repository.getMilestones(ventureId);
}

class CreateMilestoneUseCase {
  const CreateMilestoneUseCase(this._repository);
  final VenturesRepository _repository;

  Future<Result<Milestone>> call(
    int ventureId, {
    required String title,
    String? description,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return const Result.err(
        FieldFailure('title', 'Escribe qué lograste en este hito.'),
      );
    }
    if (trimmed.length > 240) {
      return const Result.err(
        FieldFailure('title', 'El título admite hasta 240 caracteres.'),
      );
    }
    final note = description?.trim();
    return _repository.createMilestone(
      ventureId,
      title: trimmed,
      description: (note == null || note.isEmpty) ? null : note,
    );
  }
}

class CompleteMilestoneUseCase {
  const CompleteMilestoneUseCase(this._repository);
  final VenturesRepository _repository;

  Future<Result<Milestone>> call(int milestoneId) =>
      _repository.completeMilestone(milestoneId);
}
