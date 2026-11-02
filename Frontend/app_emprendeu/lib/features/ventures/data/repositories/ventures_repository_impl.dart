import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/milestone.dart';
import '../../domain/entities/venture.dart';
import '../../domain/repositories/ventures_repository.dart';
import '../datasources/ventures_remote_data_source.dart';

class VenturesRepositoryImpl implements VenturesRepository {
  const VenturesRepositoryImpl(this._remote);

  final VenturesRemoteDataSource _remote;

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
  Future<Result<Venture?>> getMine() => _guard(() async {
    final list = await _remote.mine();
    return list.isEmpty ? null : list.first.toEntity();
  });

  @override
  Future<Result<Venture>> create(String name) =>
      _guard(() async => (await _remote.create(name)).toEntity());

  @override
  Future<Result<Venture>> update(
    int ventureId, {
    required String name,
    String? description,
    String? sector,
  }) => _guard(
    () async => (await _remote.update(
      ventureId,
      name: name,
      description: description,
      sector: sector,
    )).toEntity(),
  );

  @override
  Future<Result<List<Milestone>>> getMilestones(int ventureId) => _guard(
    () async => [
      for (final h in await _remote.milestones(ventureId)) h.toEntity(),
    ],
  );

  @override
  Future<Result<Milestone>> createMilestone(
    int ventureId, {
    required String title,
    String? description,
  }) => _guard(
    () async => (await _remote.createMilestone(
      ventureId,
      title: title,
      description: description,
    )).toEntity(),
  );

  @override
  Future<Result<Milestone>> completeMilestone(int milestoneId) => _guard(
    () async => (await _remote.completeMilestone(milestoneId)).toEntity(),
  );
}
