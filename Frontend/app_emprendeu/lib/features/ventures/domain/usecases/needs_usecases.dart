import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/venture_need.dart';
import '../repositories/ventures_repository.dart';

const needPriorities = ['baja', 'media', 'alta'];

class GetNeedsUseCase {
  const GetNeedsUseCase(this._repository);
  final VenturesRepository _repository;

  Future<Result<List<VentureNeed>>> call(int ventureId) =>
      _repository.getNeeds(ventureId);
}

class GetNeedCatalogUseCase {
  const GetNeedCatalogUseCase(this._repository);
  final VenturesRepository _repository;

  Future<Result<List<String>>> call() => _repository.getNeedCatalog();
}

class AddNeedUseCase {
  const AddNeedUseCase(this._repository);
  final VenturesRepository _repository;

  Future<Result<VentureNeed>> call(
    int ventureId, {
    required String name,
    String priority = 'media',
    String? description,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Result.err(
        FieldFailure('name', 'Escribe qué necesitas o qué te cuesta.'),
      );
    }
    if (trimmed.length > 160) {
      return const Result.err(
        FieldFailure('name', 'Usa hasta 160 caracteres.'),
      );
    }
    final note = description?.trim();
    return _repository.addNeed(
      ventureId,
      name: trimmed,
      priority: needPriorities.contains(priority) ? priority : 'media',
      description: (note == null || note.isEmpty) ? null : note,
    );
  }
}

class ResolveNeedUseCase {
  const ResolveNeedUseCase(this._repository);
  final VenturesRepository _repository;

  Future<Result<VentureNeed>> call(int needId) =>
      _repository.resolveNeed(needId);
}
