import '../../../../core/error/result.dart';
import '../entities/venture.dart';
import '../repositories/ventures_repository.dart';

class GetMyVentureUseCase {
  const GetMyVentureUseCase(this._repository);

  final VenturesRepository _repository;

  Future<Result<Venture?>> call() => _repository.getMine();
}
