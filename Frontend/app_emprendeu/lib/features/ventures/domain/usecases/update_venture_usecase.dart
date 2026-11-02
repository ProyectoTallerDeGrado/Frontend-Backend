import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/venture.dart';
import '../repositories/ventures_repository.dart';

class UpdateVentureUseCase {
  const UpdateVentureUseCase(this._repository);

  final VenturesRepository _repository;

  Future<Result<Venture>> call(
    int ventureId, {
    required String name,
    String? description,
    String? sector,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Result.err(
        FieldFailure('name', 'Ingresa el nombre de tu emprendimiento.'),
      );
    }
    if (trimmed.length > 160) {
      return const Result.err(
        FieldFailure('name', 'El nombre admite hasta 160 caracteres.'),
      );
    }
    String? clean(String? v) {
      final t = v?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    return _repository.update(
      ventureId,
      name: trimmed,
      description: clean(description),
      sector: clean(sector),
    );
  }
}
