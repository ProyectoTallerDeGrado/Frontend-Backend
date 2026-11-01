import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/venture.dart';
import '../repositories/ventures_repository.dart';

class CreateVentureUseCase {
  const CreateVentureUseCase(this._repository);

  final VenturesRepository _repository;

  Future<Result<Venture>> call(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Result.err(
        FieldFailure('name', 'Ingresa el nombre de tu emprendimiento.'),
      );
    }
    return _repository.create(trimmed);
  }
}
