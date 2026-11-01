import '../../../../core/error/result.dart';
import '../entities/venture.dart';

abstract interface class VenturesRepository {
  /// Primer emprendimiento del usuario, o `null` si aún no registró ninguno.
  Future<Result<Venture?>> getMine();

  Future<Result<Venture>> create(String name);
}
