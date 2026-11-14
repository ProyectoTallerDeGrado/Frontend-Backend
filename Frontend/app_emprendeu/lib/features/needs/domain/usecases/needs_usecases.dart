import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/venture_need.dart';
import '../repositories/needs_repository.dart';

/// Tope de la descripción (lo valida también el servidor).
const maxNeedDescriptionLength = 2000;

class GetNeedCategoriesUseCase {
  const GetNeedCategoriesUseCase(this._repository);
  final NeedsRepository _repository;

  Future<Result<List<NeedCategory>>> call() => _repository.getCategories();
}

class GetNeedsUseCase {
  const GetNeedsUseCase(this._repository);
  final NeedsRepository _repository;

  Future<Result<List<VentureNeed>>> call(int ventureId) =>
      _repository.getNeeds(ventureId);
}

/// Registra una necesidad o dificultad. Valida en el dispositivo lo obligatorio
/// (rubro y descripción) antes de llamar al servidor (CU24).
class ReportNeedUseCase {
  const ReportNeedUseCase(this._repository);
  final NeedsRepository _repository;

  Future<Result<VentureNeed>> call({
    required int ventureId,
    required int? categoryId,
    required NeedKind kind,
    required NeedPriority priority,
    required String description,
  }) async {
    if (categoryId == null) {
      return const Result.err(FieldFailure('category', 'Elige un rubro.'));
    }
    final text = description.trim();
    if (text.isEmpty) {
      return const Result.err(
        FieldFailure(
          'description',
          'Describe lo que necesitas o lo que te frena.',
        ),
      );
    }
    if (text.length > maxNeedDescriptionLength) {
      return const Result.err(
        FieldFailure(
          'description',
          'La descripción es muy larga (máximo $maxNeedDescriptionLength caracteres).',
        ),
      );
    }
    return _repository.report(
      ventureId: ventureId,
      categoryId: categoryId,
      kind: kind,
      priority: priority,
      description: text,
    );
  }
}
