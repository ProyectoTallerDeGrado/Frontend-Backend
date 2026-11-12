import '../../../../core/error/result.dart';
import '../entities/venture.dart';
import '../repositories/ventures_repository.dart';

/// Emprendimientos del usuario: un emprendedor puede ser parte de varios.
class GetMyVenturesUseCase {
  const GetMyVenturesUseCase(this._repository);

  final VenturesRepository _repository;

  Future<Result<List<Venture>>> call() => _repository.getMine();
}
