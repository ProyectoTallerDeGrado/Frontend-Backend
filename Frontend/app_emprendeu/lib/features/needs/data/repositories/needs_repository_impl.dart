import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/venture_need.dart';
import '../../domain/repositories/needs_repository.dart';
import '../datasources/needs_remote_data_source.dart';

class NeedsRepositoryImpl implements NeedsRepository {
  const NeedsRepositoryImpl(this._remote);

  final NeedsRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e) {
      return Result.err(mapDioException(e));
    } on TypeError {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    }
  }

  @override
  Future<Result<List<NeedCategory>>> getCategories() => _guard(
    () async => [for (final c in await _remote.categories()) c.toEntity()],
  );

  @override
  Future<Result<List<VentureNeed>>> getNeeds(int ventureId) => _guard(
    () async => [
      for (final n in (await _remote.needs(ventureId)).reversed) n.toEntity(),
    ],
  );

  @override
  Future<Result<VentureNeed>> report({
    required int ventureId,
    required int categoryId,
    required NeedKind kind,
    required NeedPriority priority,
    required String description,
  }) => _guard(
    () async => (await _remote.report(
      ventureId: ventureId,
      categoryId: categoryId,
      kind: kind,
      priority: priority,
      description: description,
    )).toEntity(),
  );
}
